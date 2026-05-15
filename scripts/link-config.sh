#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PKG_PATH="$REPO_ROOT/pi/packages/default"
TARGET_DIR="${HOME}/.pi/agent"
SETTINGS_FILE="$TARGET_DIR/settings.json"

mkdir -p "$TARGET_DIR"

python3 - <<'PY' "$SETTINGS_FILE" "$PKG_PATH"
import json
import pathlib
import sys

settings_file = pathlib.Path(sys.argv[1])
pkg_path = sys.argv[2]

if settings_file.exists():
    data = json.loads(settings_file.read_text())
else:
    data = {}

packages = data.get("packages", [])
if not isinstance(packages, list):
    packages = []

# Remove stale entries for this repo package (and prior subagents source forms), then add current one.
packages = [
    p for p in packages
    if not (
        isinstance(p, str)
        and (
            p == pkg_path
            or p.endswith("/pi/packages/default")
            or p.endswith("/share/pi-packages/pifiles-default")
            or p.endswith("/share/pi-packages/pi-subagents")
            or p == "git:github.com/nicobailon/pi-subagents"
            or p == "nicobailon/pi-subagents"
        )
    )
]
packages.append(pkg_path)

data["packages"] = packages
settings_file.write_text(json.dumps(data, indent=2) + "\n")
PY

echo "Linked default pi package into $SETTINGS_FILE"
