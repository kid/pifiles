"""Compute ``npmDepsHash`` by parsing FOD mismatch output."""

from __future__ import annotations

import re

from .nix import NixCommandError, nix_build_capture

_GOT_HASH_RE = re.compile(r"got:\s+(sha256-[A-Za-z0-9+/=]+)")


def calculate_npm_deps_hash(attr: str) -> str:
    """Build ``.#<attr>`` with a dummy npmDepsHash; extract the real one.

    Expects ``hashes.json`` to already contain the dummy hash for the attr being
    built. Returns the real SRI hash printed by Nix's FOD mismatch.
    """
    rc, output = nix_build_capture(attr)
    if rc == 0:
        # Build succeeded with the dummy hash — unexpected, hash is unchanged.
        raise NixCommandError(
            f"`nix build .#{attr}` unexpectedly succeeded with the dummy npmDepsHash"
        )
    matches = _GOT_HASH_RE.findall(output)
    if not matches:
        raise NixCommandError(
            f"could not find replacement npmDepsHash in build output for {attr}:\n{output[-2000:]}"
        )
    return matches[-1]
