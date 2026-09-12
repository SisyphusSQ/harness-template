#!/usr/bin/env python3
"""Run behavior contracts with temporary fixtures and report platform coverage."""

from pathlib import Path
import os
import shutil
import subprocess
import sys

root = Path(__file__).resolve().parents[1]
environment = {**os.environ, "PYTHONDONTWRITEBYTECODE": "1"}
result = subprocess.run(
    [sys.executable, "-m", "unittest", "discover", "-s", str(root / "tests"), "-v"],
    cwd=root, env=environment, check=False,
)
if not shutil.which("pwsh") and not shutil.which("powershell"):
    print("PowerShell runtime unavailable: wrapper execution NOT_RUN; shared core covered.")
raise SystemExit(result.returncode)
