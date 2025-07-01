#!/usr/bin/env python3
from ccbr_tools.github import get_repo_contributors, get_contrib_html

CONTRIB_MD = ["# Contributors\n"]


def main(contrib_md=CONTRIB_MD, repo="CHAMPAGNE", org="CCBR", ncol=3):
    for n, contrib in enumerate(get_repo_contributors(repo, org)):
        contrib_html = get_contrib_html(contrib).strip("\n")
        if n % ncol == 0 and n > 0:
            contrib_md += "\n"
        contrib_md.append(contrib_html)

    contrib_md.append(
        "\nView the [contributors graph on GitHub](https://github.com/CCBR/CHAMPAGNE/graphs/contributors) for more details."
    )

    with open("docs/devs/contributors.md", "w") as f:
        f.write("\n".join(contrib_md))


if __name__ == "__main__":
    main()
