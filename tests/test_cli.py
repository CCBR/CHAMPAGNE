import json
import os.path
import pathlib
import pytest
import subprocess
import tempfile
from ccbr_tools.shell import shell_run

# from champagne.src.util import run_nextflow


def test_help():
    output = subprocess.run(
        "./bin/champagne --help", capture_output=True, shell=True, text=True
    ).stdout
    assert "Usage: champagne [OPTIONS]" in output


def test_version():
    output = subprocess.run(
        "./bin/champagne --version", capture_output=True, shell=True, text=True
    ).stdout
    assert "champagne, version" in output


def test_citation():
    output = subprocess.run(
        "./bin/champagne --citation", capture_output=True, shell=True, text=True
    ).stdout
    assert "title = {CHAMPAGNE" in output


def test_preview():
    output = subprocess.run(
        "./bin/champagne run -preview -c tests/nxf/ci_stub.config --mode local",
        capture_output=True,
        shell=True,
        text=True,
        check=True,
    ).stdout
    cmd_line = {
        l.split(":")[0].strip(): l.split(":")[1].strip()
        for l in output.split("\n")
        if ":" in l
    }["cmd line"]
    assert "-preview" in cmd_line and "-resume" in cmd_line


def test_forceall():
    output = subprocess.run(
        "./bin/champagne run --forceall -preview -c tests/nxf/ci_stub.config --mode local",
        capture_output=True,
        shell=True,
        text=True,
        check=True,
    ).stdout
    cmd_line = {
        l.split(":")[0].strip(): l.split(":")[1].strip()
        for l in output.split("\n")
        if ":" in l
    }["cmd line"]
    assert "-preview" in cmd_line and "-resume" not in cmd_line


def test_init():
    with tempfile.TemporaryDirectory() as tmp_dir:
        output = shell_run(f"./bin/champagne init --output {tmp_dir}")
        outdir = pathlib.Path(tmp_dir)
        assertions = [(outdir / "nextflow.config").exists(), (outdir / "log").exists()]
    assert all(assertions)


def test_init_default():
    cwd = os.getcwd()
    with tempfile.TemporaryDirectory() as tmp_dir:
        os.chdir(tmp_dir)
        output = shell_run(f"{cwd}/bin/champagne init")
        outdir = pathlib.Path(tmp_dir)
        assertions = [(outdir / "nextflow.config").exists(), (outdir / "log").exists()]

    os.chdir(cwd)
    assert all(assertions)


def test_run_no_init():
    with pytest.raises(Exception) as exc_info:
        with tempfile.TemporaryDirectory() as tmp_dir:
            output = shell_run(
                f"./bin/champagne run --output {tmp_dir} --mode local",
                check=True,
                capture_output=True,
            )
            assertions = ["Hint: you must initialize the output directory" in output]
            assert all(assertions)
