#!/usr/bin/env bash
set -euo pipefail

if ! command -v node >/dev/null 2>&1; then
  echo "node is required" >&2
  exit 1
fi

if ! command -v npm >/dev/null 2>&1; then
  echo "npm is required" >&2
  exit 1
fi

npm ci
"$(dirname "$0")/link-config.sh"

echo "Standalone install complete."
echo "Run: npx pi --help"
