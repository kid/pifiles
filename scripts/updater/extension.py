"""High-level updater for pifiles GitHub-sourced pi extensions.

Every extension follows the same shape (see ``nix/pkgs/by-name/<pkg>/``):
  - ``hashes.json`` pinning ``version`` (= GitHub tag, minus ``v``), ``rev``,
    ``narHash`` and ``npmDepsHash``
  - ``package-lock.json`` copied into the source via ``postPatch``
  - ``package.nix`` building with ``buildNpmPackage`` from
    ``builtins.fetchTree { type = "github"; ... }``

This module bumps one such package to a new GitHub tag (or default-branch HEAD).
"""

from __future__ import annotations

import sys
from pathlib import Path

from . import (
    DUMMY_NPM_DEPS_HASH,
    calculate_npm_deps_hash,
    fetch_github_default_branch_head,
    fetch_github_latest_release,
    load_hashes,
    prefetch_github_tree,
    regenerate_package_lock,
    save_hashes,
    should_update,
)
from .github import resolve_github_tag_commit


def update_extension(
    package_dir: Path,
    *,
    attr: str | None = None,
    track: str = "release",
) -> bool:
    """Update one extension in-place.

    ``track`` is either ``"release"`` (use latest tag) or ``"main"`` (track the
    default branch). Returns ``True`` if anything changed.
    """
    hashes_path = package_dir / "hashes.json"
    lock_path = package_dir / "package-lock.json"
    data = load_hashes(hashes_path)

    owner = data["owner"]
    repo = data["repo"]
    current_version = data["version"]
    current_rev = data["rev"]
    attr = attr or data.get("attr") or package_dir.name

    if track == "release":
        latest = fetch_github_latest_release(owner, repo)
        if not latest:
            print(f"{attr}: no releases/tags found")
            return False
        if not should_update(current_version, latest):
            print(f"{attr}: already at {current_version}")
            return False
        new_rev = resolve_github_tag_commit(owner, repo, latest)
        new_version = latest
    elif track == "main":
        _, new_rev = fetch_github_default_branch_head(owner, repo)
        if new_rev == current_rev:
            print(f"{attr}: already at HEAD {current_rev[:12]}")
            return False
        new_version = new_rev[:12]
    else:
        raise ValueError(f"unknown track: {track!r}")

    print(f"{attr}: {current_version} -> {new_version} ({new_rev[:12]})")

    print(f"{attr}: prefetching github:{owner}/{repo}/{new_rev} ...")
    nar_hash = prefetch_github_tree(owner, repo, new_rev)

    print(f"{attr}: regenerating package-lock.json ...")
    regenerate_package_lock(owner, repo, new_rev, lock_path)

    data.update(
        {
            "version": new_version,
            "rev": new_rev,
            "narHash": nar_hash,
            "npmDepsHash": DUMMY_NPM_DEPS_HASH,
        }
    )
    save_hashes(hashes_path, data)

    print(f"{attr}: computing npmDepsHash ...")
    real_hash = calculate_npm_deps_hash(attr)
    data["npmDepsHash"] = real_hash
    save_hashes(hashes_path, data)
    print(f"{attr}: updated to {new_version}")
    return True


def main_for(package_dir: Path) -> None:
    """Entry-point helper for per-package ``update.py`` scripts."""
    track = "release"
    if len(sys.argv) > 1 and sys.argv[1] in {"release", "main"}:
        track = sys.argv[1]
    changed = update_extension(package_dir, track=track)
    sys.exit(0 if changed or True else 1)
