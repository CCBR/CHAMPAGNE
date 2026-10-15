import os.path
import pathlib
import subprocess
import tempfile
from unittest.mock import Mock

import ccbr_tools.pipeline.nextflow
import pytest
from ccbr_tools.shell import shell_run
from click.testing import CliRunner

from src.__main__ import cli


def test_help():
    output = subprocess.run(
        "./bin/champagne --help",
        capture_output=True,
        shell=True,
        text=True,
        check=False,
    ).stdout
    assert "Usage: champagne [OPTIONS]" in output


def test_version():
    output = subprocess.run(
        "./bin/champagne --version",
        capture_output=True,
        shell=True,
        text=True,
        check=False,
    ).stdout
    assert "champagne, version" in output


def test_citation():
    output = subprocess.run(
        "./bin/champagne --citation",
        capture_output=True,
        shell=True,
        text=True,
        check=False,
    ).stdout
    assert "title = {CHAMPAGNE" in output


@pytest.fixture
def mock_nextflow(monkeypatch, tmp_path):
    """Capture Nextflow commands without launching external processes."""
    (tmp_path / "nextflow.config").touch()
    mock_run = Mock()
    monkeypatch.setattr(ccbr_tools.pipeline.nextflow, "shell_run", mock_run)
    return mock_run


def test_preview(mock_nextflow, tmp_path):
    result = CliRunner().invoke(
        cli, ["run", "--output", str(tmp_path), "--mode", "local", "-preview"]
    )
    assert result.exit_code == 0, result.output
    mock_nextflow.assert_called_once()
    cmd_line = mock_nextflow.call_args.args[0]
    assert "-preview" in cmd_line and "-resume" in cmd_line


def test_forceall(mock_nextflow, tmp_path):
    result = CliRunner().invoke(
        cli,
        ["run", "--output", str(tmp_path), "--mode", "local", "--forceall", "-preview"],
    )
    assert result.exit_code == 0, result.output
    mock_nextflow.assert_called_once()
    cmd_line = mock_nextflow.call_args.args[0]
    assert "-preview" in cmd_line and "-resume" not in cmd_line


def test_init():
    with tempfile.TemporaryDirectory() as tmp_dir:
        outdir = pathlib.Path(tmp_dir)
        subprocess.run(
            f"./bin/champagne init --output {tmp_dir}",
            capture_output=True,
            shell=True,
            text=True,
            check=True,
        )
        assert (outdir / "nextflow.config").exists()
        assert (outdir / "log").exists()


def test_init_default():
    cwd = os.getcwd()
    with tempfile.TemporaryDirectory() as tmp_dir:
        os.chdir(tmp_dir)
        outdir = pathlib.Path(tmp_dir)
        subprocess.run(
            "champagne init",
            capture_output=True,
            shell=True,
            text=True,
            check=True,
        )
        assert (outdir / "nextflow.config").exists()
        assert (outdir / "log").exists()

    os.chdir(cwd)


def test_run_no_init():
    with (
        pytest.raises(subprocess.CalledProcessError),
        tempfile.TemporaryDirectory() as tmp_dir,
    ):
        output = shell_run(
            f"./bin/champagne run --output {tmp_dir} --mode local",
            check=True,
            capture_output=True,
        )
        assertions = ["Hint: you must initialize the output directory" in output]
        assert all(assertions)
