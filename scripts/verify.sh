#!/usr/bin/env bash
set -euo pipefail

if command -v pi >/dev/null 2>&1; then
  echo "pi binary: $(command -v pi)"
  pi --version || true
else
  echo "pi not in PATH"
fi

if command -v qmd >/dev/null 2>&1; then
  echo "qmd binary: $(command -v qmd)"
  qmd --version || true
elif [[ -x "$(pwd)/node_modules/.bin/qmd" ]]; then
  echo "qmd binary: $(pwd)/node_modules/.bin/qmd"
  "$(pwd)/node_modules/.bin/qmd" --version || true
else
  echo "qmd not found"
fi

echo "settings: ${HOME}/.pi/agent/settings.json"
if [[ -f "${HOME}/.pi/agent/settings.json" ]]; then
  cat "${HOME}/.pi/agent/settings.json"
else
  echo "(missing)"
fi
