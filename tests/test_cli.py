import json
import os.path
import subprocess
import tempfile


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
