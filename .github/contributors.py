#!/usr/bin/env python3
from ccbr_tools.github import get_repo_contributors, get_user_info

CONTRIB_MD = ["# Contributors\n"]


def get_contrib_html(contrib):
    user_login = contrib["login"]
    user_info = get_user_info(user_login)
    user_name = user_info["name"] if user_info["name"] else user_login
    avatar_url = contrib["avatar_url"]
    profile_url = contrib["html_url"]
    return (
        f"<a href='{profile_url}' title='{user_name}' style='display: inline-block; text-align: center;'>"
        f"<img src='{avatar_url}' alt='{user_name}' style='border-radius: 50%; width: 30%;'>"
        f"<br>{user_name}</a>"
    )


def main(contribs_md=CONTRIB_MD, repo="CHAMPAGNE", org="CCBR", ncol=3):
    contribs_str = "|" + " |" * ncol + "\n|" + "---|" * ncol + "\n| "
    nmod = ncol - 1
    contribs = get_repo_contributors(repo, org)
    for n, contrib in enumerate(contribs):
        contrib_html = get_contrib_html(contrib)
        if n % nmod == 0 and n > 0:
            contrib_html += " |\n"
            if n < len(contribs) - 1:
                contrib_html += "| "
        else:
            contrib_html += " | "
        contribs_str += contrib_html
    contribs_md.append(contribs_str)

    contribs_md.append(
        "\nView the [contributors graph on GitHub](https://github.com/CCBR/CHAMPAGNE/graphs/contributors) for more details."
    )

    with open("docs/devs/contributors.md", "w") as f:
        f.write("\n".join(contribs_md))


if __name__ == "__main__":
    main()
