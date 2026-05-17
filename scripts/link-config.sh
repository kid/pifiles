#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEFAULT_PKG_PATH="$REPO_ROOT/pi/packages/default"
PI_MEMORY_PKG_PATH="$REPO_ROOT/node_modules/pi-memory"
TARGET_DIR="${HOME}/.pi/agent"
SETTINGS_FILE="$TARGET_DIR/settings.json"

mkdir -p "$TARGET_DIR"

if [[ ! -d "$PI_MEMORY_PKG_PATH" ]]; then
  echo "Missing $PI_MEMORY_PKG_PATH; run npm ci first" >&2
  exit 1
fi

python3 - <<'PY' "$SETTINGS_FILE" "$DEFAULT_PKG_PATH" "$PI_MEMORY_PKG_PATH"
import json
import pathlib
import sys

settings_file = pathlib.Path(sys.argv[1])
default_pkg_path = sys.argv[2]
pi_memory_pkg_path = sys.argv[3]

if settings_file.exists():
    data = json.loads(settings_file.read_text())
else:
    data = {}

packages = data.get("packages", [])
if not isinstance(packages, list):
    packages = []

legacy = {
    "git:github.com/nicobailon/pi-subagents",
    "nicobailon/pi-subagents",
    "git:github.com/jayzeng/pi-memory",
    "jayzeng/pi-memory",
    "npm:pi-memory",
    "pi-memory",
}

suffixes = (
    "/pi/packages/default",
    "/share/pi-packages/pifiles-default",
    "/share/pi-packages/pi-subagents",
    "/share/pi-packages/pi-memory",
    "/node_modules/pi-memory",
)

tracked_paths = {default_pkg_path, pi_memory_pkg_path}


def is_stale(entry):
    if isinstance(entry, str):
        return entry in tracked_paths or entry in legacy or entry.endswith(suffixes)
    if isinstance(entry, dict):
        source = entry.get("source")
        return isinstance(source, str) and (
            source in tracked_paths or source in legacy or source.endswith(suffixes)
        )
    return False

packages = [p for p in packages if not is_stale(p)]
packages.append(default_pkg_path)
packages.append(pi_memory_pkg_path)

data["packages"] = packages
settings_file.write_text(json.dumps(data, indent=2) + "\n")
PY

echo "Linked default pi packages into $SETTINGS_FILE"
