#!/usr/bin/env python3
"""Update a locally-packaged pi extension to its latest GitHub release.

Usage:
    ./scripts/update-extension.py <pkg-name> [release|main]

Examples:
    ./scripts/update-extension.py pi-subagents
    ./scripts/update-extension.py pi-boomerang main
    ./scripts/update-extension.py all          # update every extension
"""

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PKGS_DIR = ROOT / "nix" / "pkgs" / "by-name"

sys.path.insert(0, str(ROOT / "scripts"))
from updater.extension import main_for  # noqa: E402


def all_extension_dirs() -> list[Path]:
    return sorted(
        p for p in PKGS_DIR.iterdir() if (p / "hashes.json").exists()
    )


if __name__ == "__main__":
    args = sys.argv[1:]
    if not args:
        print(__doc__)
        sys.exit(1)

    pkg_name = args[0]
    track = args[1] if len(args) > 1 else "release"

    if pkg_name == "all":
        for pkg_dir in all_extension_dirs():
            main_for(pkg_dir, track=track)
    else:
        pkg_dir = PKGS_DIR / pkg_name
        if not pkg_dir.is_dir():
            print(f"error: unknown package {pkg_name!r}", file=sys.stderr)
            sys.exit(1)
        main_for(pkg_dir, track=track)
