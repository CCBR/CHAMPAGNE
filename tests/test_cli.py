import json
import os.path
import subprocess
import tempfile

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
        "./bin/champagne run -preview -c tests/nxf/ci_stub.config",
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
        "./bin/champagne run --forceall -preview -c tests/nxf/ci_stub.config",
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
