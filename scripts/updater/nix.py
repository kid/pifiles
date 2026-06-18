"""Wrappers around the ``nix`` CLI."""

from __future__ import annotations

import json
import subprocess
from typing import Any


class NixCommandError(RuntimeError):
    """Raised when a ``nix`` invocation fails unexpectedly."""


def _run(cmd: list[str], *, check: bool = True) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        cmd,
        capture_output=True,
        text=True,
        check=check,
    )


def nix_eval(expr: str, *, json_output: bool = True) -> Any:
    """Evaluate a Nix expression. Returns parsed JSON when ``json_output``."""
    cmd = ["nix", "eval", "--impure", "--expr", expr]
    if json_output:
        cmd.append("--json")
    proc = _run(cmd, check=False)
    if proc.returncode != 0:
        raise NixCommandError(proc.stderr.strip())
    return json.loads(proc.stdout) if json_output else proc.stdout.strip()


def nix_build_capture(attr: str) -> tuple[int, str]:
    """Try ``nix build .#<attr>``; return (returncode, combined stderr+stdout)."""
    proc = subprocess.run(
        ["nix", "build", "--no-link", "--print-build-logs", f".#{attr}"],
        capture_output=True,
        text=True,
        check=False,
    )
    return proc.returncode, (proc.stderr or "") + (proc.stdout or "")


def nix_flake_prefetch_github(owner: str, repo: str, rev: str) -> dict[str, Any]:
    """Run ``nix flake prefetch github:owner/repo/rev --json``."""
    url = f"github:{owner}/{repo}/{rev}"
    proc = _run(
        ["nix", "flake", "prefetch", url, "--json", "--refresh"],
        check=False,
    )
    if proc.returncode != 0:
        raise NixCommandError(
            f"nix flake prefetch {url} failed:\n{proc.stderr.strip()}"
        )
    return json.loads(proc.stdout)
