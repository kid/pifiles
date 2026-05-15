#!/usr/bin/env bash
set -euo pipefail

if command -v pi >/dev/null 2>&1; then
  echo "pi binary: $(command -v pi)"
  pi --version || true
else
  echo "pi not in PATH"
fi

echo "settings: ${HOME}/.pi/agent/settings.json"
if [[ -f "${HOME}/.pi/agent/settings.json" ]]; then
  cat "${HOME}/.pi/agent/settings.json"
else
  echo "(missing)"
fi
