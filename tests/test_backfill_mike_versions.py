"""Tests for .github/backfill_mike_versions.py (pure helpers only)."""

import importlib.util
from pathlib import Path

import pytest

pytest.importorskip("yaml")
pytest.importorskip("quarto_version_selector")

SCRIPT = Path(__file__).resolve().parents[1] / ".github" / "backfill_mike_versions.py"
spec = importlib.util.spec_from_file_location("backfill", SCRIPT)
backfill = importlib.util.module_from_spec(spec)
spec.loader.exec_module(backfill)

NAV = [
    {"Home": "index.md"},
    {
        "Usage": [
            {"Getting Started": "getting-started.md"},
            {"Ext": "https://example.com"},
        ]
    },
    {"Changelog": "changelog.md"},
]


def test_latest_tag_per_version():
    tags = ["v0.2.0", "v0.2.10", "v0.2.2", "v0.3.0", "v0.4.0-rc1", "not-a-tag"]
    assert backfill.latest_tag_per_version(tags) == {"0.2": "v0.2.10", "0.3": "v0.3.0"}


def test_nav_to_sidebar_and_files():
    assert backfill.nav_to_sidebar(NAV) == [
        {"href": "index.md", "text": "Home"},
        {
            "section": "Usage",
            "contents": [
                {"href": "getting-started.md", "text": "Getting Started"},
                {"href": "https://example.com", "text": "Ext"},
            ],
        },
        {"href": "changelog.md", "text": "Changelog"},
    ]
    assert sorted(backfill.nav_files(NAV)) == [
        "changelog.md",
        "getting-started.md",
        "index.md",
    ]


def test_convert_snippets_and_links(tmp_path):
    docs = tmp_path / "docs"
    (docs / "devs").mkdir(parents=True)
    (docs / "index.md").write_text('--8<-- "README.md"\n')
    (docs / "devs" / "contributing.md").write_text(
        '--8<-- ".github/CONTRIBUTING.md"\nsee [x](/nextflow.md)\n'
    )
    backfill.convert_snippets(docs)
    backfill.fix_root_links(docs)
    assert (docs / "index.md").read_text() == "{{< include ../README.md >}}\n"
    assert (docs / "devs" / "contributing.md").read_text() == (
        "{{< include ../../.github/CONTRIBUTING.md >}}\nsee [x](../nextflow.md)\n"
    )


def test_fix_repo_links(tmp_path):
    (tmp_path / "README.md").write_text(
        "[c](.github/CONTRIBUTING.md) [s](/assets/s.csv) [d](https://x.org)\n"
    )
    backfill.fix_repo_links(tmp_path, "https://github.com/CCBR/CHAMPAGNE", "v0.2.2")
    base = "https://github.com/CCBR/CHAMPAGNE/blob/v0.2.2/"
    assert (tmp_path / "README.md").read_text() == (
        f"[c]({base}.github/CONTRIBUTING.md) [s]({base}assets/s.csv) [d](https://x.org)\n"
    )
