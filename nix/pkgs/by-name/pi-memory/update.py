#!/usr/bin/env python3
"""Update pi-memory to the latest GitHub release."""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(ROOT / "scripts"))

from updater.extension import main_for  # noqa: E402

if __name__ == "__main__":
    main_for(Path(__file__).parent)
