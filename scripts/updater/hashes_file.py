"""Read/write per-package ``hashes.json``."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any


def load_hashes(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text())


def save_hashes(path: Path, data: dict[str, Any]) -> None:
    path.write_text(json.dumps(data, indent=2) + "\n")
