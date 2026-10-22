#!/usr/bin/env python3
"""
Re-render docs of past releases (originally built with mkdocs + mike) with Quarto
and deploy them with quarto-version-selector.

For every version listed in the docs branch's ``versions.json`` (except ``dev``),
the newest release tag matching that ``major.minor`` is checked out into a
temporary git worktree. Its ``mkdocs.yml`` nav is converted to a Quarto sidebar,
mkdocs ``--8<--`` snippets are converted to Quarto includes, the current
``docs/_extensions`` are copied in, and the site is rendered and deployed to
``<branch>/<major.minor>/``. Aliases from ``versions.json`` (e.g. ``latest``)
are kept.

Deploys are committed to the local docs branch only; review them and push with
``git push origin gh-pages`` (or pass ``--push``).

Requires: quarto, git, pyyaml, quarto-version-selector.

Example usage::

    python .github/backfill_mike_versions.py --dry-run
    python .github/backfill_mike_versions.py --versions 0.6 0.7
    git push origin gh-pages
"""

from __future__ import annotations

import argparse
import json
import re
import shutil
import subprocess
import tempfile
from pathlib import Path

import yaml
from quarto_version_selector.deploy import deploy
from quarto_version_selector.versions import get_major_minor_version

SNIPPET = re.compile(r'^--8<--[ \t]+"([^"]+)"[ \t]*$', re.MULTILINE)


class _MkdocsLoader(yaml.SafeLoader):
    """SafeLoader that ignores mkdocs' ``!!python/name:`` tags."""


_MkdocsLoader.add_multi_constructor(
    "tag:yaml.org,2002:python/", lambda loader, suffix, node: None
)


def _git(*args: str, cwd: str | Path = ".") -> str:
    """Run git and return stripped stdout."""
    return subprocess.run(
        ["git", *args], cwd=cwd, check=True, capture_output=True, text=True
    ).stdout.strip()


def latest_tag_per_version(tags: list[str]) -> dict[str, str]:
    """
    Map each ``major.minor`` to its newest release tag.

    Args:
        tags: Tag names, e.g. ``["v0.2.0", "v0.2.2"]``.

    Returns:
        ``{"0.2": "v0.2.2", ...}``; tags that are not semantic versions are skipped.
    """
    best: dict[str, tuple[tuple[int, ...], str]] = {}
    for tag in tags:
        version = get_major_minor_version(tag, strict_semver=True)
        if not version or "-" in tag:
            continue
        key = tuple(int(p) for p in tag.lstrip("v").split("+")[0].split("."))
        if version not in best or key > best[version][0]:
            best[version] = (key, tag)
    return {version: tag for version, (_, tag) in best.items()}


def nav_to_sidebar(nav: list) -> list:
    """
    Convert an mkdocs ``nav`` list into Quarto ``website.sidebar.contents``.

    Args:
        nav: The ``nav`` value from mkdocs.yml.

    Returns:
        Quarto sidebar contents.
    """
    contents = []
    for item in nav or []:
        if isinstance(item, str):
            contents.append(item)
            continue
        for text, target in item.items():
            if isinstance(target, list):
                contents.append({"section": text, "contents": nav_to_sidebar(target)})
            else:
                contents.append({"href": target, "text": text})
    return contents


def nav_files(nav: list) -> list[str]:
    """Return every local page referenced by an mkdocs nav."""
    files = []
    for entry in nav_to_sidebar(nav):
        stack = [entry]
        while stack:
            item = stack.pop()
            if isinstance(item, str):
                files.append(item)
            elif "section" in item:
                stack.extend(item["contents"])
            elif not str(item["href"]).startswith("http"):
                files.append(item["href"])
    return files


def convert_snippets(docs_dir: Path) -> None:
    """Replace mkdocs ``--8<-- "path"`` snippets with Quarto include shortcodes."""
    for md in docs_dir.rglob("*.md"):
        text = md.read_text()
        if "--8<--" not in text:
            continue
        depth = len(md.relative_to(docs_dir).parts) - 1
        prefix = "../" * (depth + 1)
        md.write_text(SNIPPET.sub(rf"{{{{< include {prefix}\1 >}}}}", text))


def fix_root_links(docs_dir: Path) -> None:
    """Rewrite root-relative markdown links like ``](/nextflow.md)`` to page-relative ones."""
    for md in docs_dir.rglob("*.md"):
        depth = len(md.relative_to(docs_dir).parts) - 1
        prefix = "../" * depth or "./"
        text = md.read_text()
        fixed = re.sub(r"\]\(/(?!/)([^)]+\.md[^)]*)\)", rf"]({prefix}\1)", text)
        if fixed != text:
            md.write_text(fixed)


def fix_repo_links(root: Path, repo_url: str, tag: str) -> None:
    """
    Point README links to repo files (e.g. ``.github/CONTRIBUTING.md``, ``/assets/x.csv``)
    at GitHub, since the README is rendered inside the docs site.
    """
    readme = root / "README.md"
    if not readme.is_file() or not repo_url:
        return
    base = f"{repo_url.rstrip('/')}/blob/{tag}/"
    text = readme.read_text()
    fixed = re.sub(
        r"\]\(/?((?:\.github|assets|conf|bin)/[^)]+)\)",
        lambda m: f"]({base}{m.group(1)})",
        text,
    )
    if fixed != text:
        readme.write_text(fixed)


def quarto_config(mkdocs: dict, version: str, template: dict) -> dict:
    """
    Build a ``_quarto.yml`` for an old release.

    The current ``_quarto.yml`` (``template``) supplies the theme, filters, navbar
    and footer; the old release's mkdocs nav supplies the sidebar and the pages
    to render.

    Args:
        mkdocs: Parsed mkdocs.yml of the old release.
        version: ``major.minor`` being built.
        template: Parsed current docs/_quarto.yml.

    Returns:
        The new Quarto config.
    """
    config = json.loads(json.dumps(template))
    nav = mkdocs.get("nav", [])
    files = nav_files(nav)
    config["project"]["render"] = files + [f for f in ["nextflow.md"] if f not in files]
    config["project"]["resources"] = ["examples/*.html"]
    website = config.setdefault("website", {})
    website["sidebar"] = {"style": "docked", "contents": nav_to_sidebar(nav)}
    # navbar links from the current site may point at pages that do not exist yet
    navbar = website.get("navbar", {})
    navbar["left"] = [{"text": "Home", "href": "index.md"}]
    return config


def build_version(
    tag: str, version: str, repo: Path, template: dict, extensions: Path, out: Path
) -> Path:
    """
    Render the docs of ``tag`` with Quarto into ``out`` and return the site dir.

    Raises:
        FileNotFoundError: If the tag has no mkdocs.yml.
        subprocess.CalledProcessError: If quarto render fails.
    """
    _git("worktree", "add", "--detach", str(out), tag, cwd=repo)
    mkdocs_path = out / "mkdocs.yml"
    if not mkdocs_path.is_file():
        raise FileNotFoundError(f"{tag} has no mkdocs.yml")
    mkdocs = yaml.load(mkdocs_path.read_text(), Loader=_MkdocsLoader)
    docs = out / mkdocs.get("docs_dir", "docs")
    convert_snippets(docs)
    fix_repo_links(out, mkdocs.get("repo_url", ""), tag)
    fix_root_links(docs)
    config = quarto_config(mkdocs, version, template)
    config["project"]["render"] = [
        f for f in config["project"]["render"] if (docs / f).is_file()
    ]
    (docs / "_quarto.yml").write_text(yaml.safe_dump(config, sort_keys=False))
    shutil.rmtree(docs / "_extensions", ignore_errors=True)
    shutil.copytree(extensions, docs / "_extensions")
    subprocess.run(["quarto", "render", str(docs)], check=True)
    return docs / config["project"].get("output-dir", "_site")


def main() -> None:
    """Re-render and deploy every non-dev version listed in versions.json."""
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument(
        "--docs-dir", default="docs", help="Current Quarto project dir (default: docs)."
    )
    parser.add_argument(
        "--branch", default="gh-pages", help="Docs branch (default: gh-pages)."
    )
    parser.add_argument(
        "--remote", default="origin", help="Git remote (default: origin)."
    )
    parser.add_argument(
        "--versions", nargs="*", help="Only these major.minor versions."
    )
    parser.add_argument(
        "--push", action="store_true", help="Push each deploy to the remote."
    )
    parser.add_argument("--dry-run", action="store_true", help="Only print the plan.")
    args = parser.parse_args()

    repo = Path(_git("rev-parse", "--show-toplevel"))
    try:
        _git(
            "fetch",
            args.remote,
            f"+{args.branch}:refs/remotes/{args.remote}/{args.branch}",
            cwd=repo,
        )
    except subprocess.CalledProcessError as err:
        raise RuntimeError(
            f"Could not fetch {args.remote}/{args.branch}: {err.stderr.strip()}"
        ) from err
    deployed = json.loads(
        _git("show", f"{args.remote}/{args.branch}:versions.json", cwd=repo)
    )
    tags = latest_tag_per_version(_git("tag", cwd=repo).splitlines())
    template = yaml.safe_load((repo / args.docs_dir / "_quarto.yml").read_text())
    extensions = repo / args.docs_dir / "_extensions"

    plan = []
    for entry in deployed:
        version = entry["version"]
        if version == "dev" or (args.versions and version not in args.versions):
            continue
        if version not in tags:
            raise ValueError(
                f"No release tag found for deployed version {version}. Fetch tags with `git fetch --tags`."
            )
        plan.append((version, tags[version], entry.get("aliases", [])))
    for version, tag, aliases in plan:
        print(f"{version}: {tag} aliases={aliases}")
    if args.dry_run:
        return

    # oldest first so the newest release's aliases (e.g. latest) are written last
    for version, tag, aliases in sorted(
        plan, key=lambda p: [int(x) for x in p[0].split(".")]
    ):
        with tempfile.TemporaryDirectory() as tmp:
            worktree = Path(tmp, "src")
            try:
                site = build_version(tag, version, repo, template, extensions, worktree)
                deploy(
                    version,
                    aliases,
                    site_dir=site,
                    branch=args.branch,
                    set_default="latest" if "latest" in aliases else None,
                    remote=args.remote,
                    push=args.push,
                    repo=repo,
                    message=f"docs: redeploy {version} ({tag}) with quarto",
                )
            finally:
                _git("worktree", "remove", "--force", str(worktree), cwd=repo)


if __name__ == "__main__":
    main()
