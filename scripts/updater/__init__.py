"""Minimal Nix package updater library for pifiles extensions.

Provides helpers for:
  - fetching latest GitHub release/tag (``github``)
  - prefetching a github tree via ``nix flake prefetch`` (``github``)
  - regenerating ``package-lock.json`` for an npm package (``npm``)
  - computing ``npmDepsHash`` via fixed-output build failure (``deps``)
  - reading/writing per-package ``hashes.json`` (``hashes_file``)
  - semver comparison (``version``)
"""

from .deps import calculate_npm_deps_hash
from .github import (
    fetch_github_latest_release,
    fetch_github_default_branch_head,
    prefetch_github_tree,
)
from .hashes_file import load_hashes, save_hashes
from .nix import NixCommandError, nix_build_capture, nix_eval
from .npm import regenerate_package_lock
from .version import should_update

DUMMY_NPM_DEPS_HASH = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
DUMMY_NAR_HASH = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="

__all__ = [
    "DUMMY_NAR_HASH",
    "DUMMY_NPM_DEPS_HASH",
    "NixCommandError",
    "calculate_npm_deps_hash",
    "fetch_github_default_branch_head",
    "fetch_github_latest_release",
    "load_hashes",
    "nix_build_capture",
    "nix_eval",
    "prefetch_github_tree",
    "regenerate_package_lock",
    "save_hashes",
    "should_update",
]
