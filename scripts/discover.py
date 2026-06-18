#!/usr/bin/env python3
"""Emit the matrix of updatable extension packages for CI.

Writes a single line ``matrix=<json>`` and ``has-updates=<bool>`` to
``$GITHUB_OUTPUT`` (when running under Actions) and to stdout otherwise.

When the ``PACKAGES`` env var is set (space-separated list of attr names) only
those packages are emitted.
"""

from __future__ import annotations

import json
import os
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PKGS_DIR = ROOT / "nix" / "pkgs" / "by-name"


def discover() -> list[dict[str, str]]:
    selected = {p for p in os.environ.get("PACKAGES", "").split() if p}
    entries: list[dict[str, str]] = []
    for pkg_dir in sorted(PKGS_DIR.iterdir()):
        if not (pkg_dir / "hashes.json").exists():
            continue
        name = pkg_dir.name
        if selected and name not in selected:
            continue
        entries.append({"name": name})
    return entries


def main() -> None:
    entries = discover()
    matrix = {"include": entries}
    has_updates = bool(entries)
    out = os.environ.get("GITHUB_OUTPUT")
    payload = (
        f"matrix={json.dumps(matrix, separators=(',', ':'))}\n"
        f"has-updates={'true' if has_updates else 'false'}\n"
    )
    if out:
        with open(out, "a") as fh:
            fh.write(payload)
    sys.stdout.write(payload)


if __name__ == "__main__":
    main()
