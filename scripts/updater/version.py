"""Semver-ish comparison."""

from __future__ import annotations


def _parts(v: str) -> list[int]:
    out: list[int] = []
    for chunk in v.lstrip("v").split("."):
        digits = ""
        for ch in chunk:
            if ch.isdigit():
                digits += ch
            else:
                break
        out.append(int(digits) if digits else 0)
    return out


def should_update(current: str, latest: str | None) -> bool:
    if not latest:
        return False
    if current == latest:
        return False
    try:
        return _parts(latest) > _parts(current)
    except ValueError:
        return current != latest
