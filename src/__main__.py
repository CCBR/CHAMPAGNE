"""
Entrypoint for CHAMPAGNE CLI

Check out the wiki for a detailed look at customizing this file:
https://github.com/beardymcjohnface/Snaketool/wiki/Customising-your-Snaketool
"""

import os
import click
from .util import (
    nek_base,
    get_version,
    copy_config,
    OrderedCommands,
    run_nextflow,
    print_citation,
)


def common_options(func):
    """Common options decorator for use with click commands."""
    options = [
        click.argument("nextflow_args", nargs=-1),
    ]
    for option in reversed(options):
        func = option(func)
    return func


@click.group(
    cls=OrderedCommands, context_settings=dict(help_option_names=["-h", "--help"])
)
@click.version_option(get_version(), "-v", "--version", is_flag=True)
@click.option(
    "--citation",
    is_flag=True,
    callback=print_citation,
    expose_value=False,
    is_eager=True,
    help="Print the citation in bibtex format and exit.",
)
def cli():
    """CHromAtin iMmuno PrecipitAtion sequencinG aNalysis pipEline

    For more options, run:
    champagne [command] --help"""
    pass


help_msg_extra = """
\b
EXAMPLES:
Execute with slurm:
    champagne run ... --mode slurm
Preview the processes that will run:
    champagne run ... --mode local -preview
Add nextflow args (anything supported by `nextflow run`):
    champagne run ... -work-dir path/to/workDir
Run with a specific installation of champagne:
    champagne run --main path/to/champagne/main.nf ...
Run with a specific tag, branch, or commit from GitHub:
    champagne run --main CCBR/CHAMPAGNE -r v0.1.0 ...
"""


@click.command(
    epilog=help_msg_extra,
    context_settings=dict(
        help_option_names=["-h", "--help"], ignore_unknown_options=True
    ),
)
@click.option(
    "--main",
    "main_path",
    help="Path to the champagne main.nf file or the GitHub repo (CCBR/CHAMPAGNE). Defaults to the version installed in the $PATH.",
    type=str,
    default=nek_base(os.path.join("main.nf")),
    show_default=True,
)
@click.option(
    "--mode",
    "_mode",
    help="Run mode (slurm, local)",
    type=str,
    default="local",
    show_default=True,
)
@click.option(
    "--forceall",
    "-F",
    "force_all",
    help="Force all processes to run (i.e. do not use nextflow -resume)",
    is_flag=True,
    default=False,
    show_default=True,
)
@common_options
def run(main_path, _mode, force_all, **kwargs):
    """Run the workflow"""
    if (  # this is the only acceptable github repo option for champagne
        main_path != "CCBR/CHAMPAGNE"
    ):
        # make sure the path exists
        if not os.path.exists(main_path):
            raise FileNotFoundError(
                f"Path to the champagne main.nf file not found: {main_path}"
            )

    run_nextflow(
        nextfile_path=main_path,
        mode=_mode,
        force_all=force_all,
        **kwargs,
    )


@click.command()
def init(**kwargs):
    """Initialize the working directory by copying the system default config files"""
    paths = ("nextflow.config", "conf/", "assets/")
    copy_config(paths)
    if not os.path.exists("log/"):
        os.mkdir("log/")


@click.command()
def citation(**kwargs):
    """Print the citation"""
    print_citation()


cli.add_command(run)
cli.add_command(init)


def main():
    cli()


cli(prog_name="champagne")

if __name__ == "__main__":
    main()
