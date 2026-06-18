"""GitHub helpers: latest release/tag lookup + tree narHash prefetch."""

from __future__ import annotations

import json
import os
import urllib.error
import urllib.request
from typing import Any

from .nix import nix_flake_prefetch_github


def _request(url: str) -> dict[str, Any] | list[Any]:
    headers = {
        "Accept": "application/vnd.github+json",
        "User-Agent": "pifiles-updater",
    }
    token = os.environ.get("GITHUB_TOKEN") or os.environ.get("GH_TOKEN")
    if token:
        headers["Authorization"] = f"Bearer {token}"
    req = urllib.request.Request(url, headers=headers)
    with urllib.request.urlopen(req, timeout=30) as resp:
        return json.loads(resp.read().decode("utf-8"))


def fetch_github_latest_release(owner: str, repo: str) -> str | None:
    """Return the latest release tag (without ``v`` prefix), or ``None``.

    Falls back to the highest-versioned tag when the repo has no releases.
    """
    try:
        data = _request(f"https://api.github.com/repos/{owner}/{repo}/releases/latest")
        if isinstance(data, dict) and data.get("tag_name"):
            return str(data["tag_name"]).lstrip("v")
    except urllib.error.HTTPError as e:
        if e.code != 404:
            raise

    # Fall back to tags list (newest first by creation date).
    tags = _request(f"https://api.github.com/repos/{owner}/{repo}/tags?per_page=1")
    if isinstance(tags, list) and tags:
        return str(tags[0]["name"]).lstrip("v")
    return None


def fetch_github_default_branch_head(owner: str, repo: str) -> tuple[str, str]:
    """Return ``(branch, commit_sha)`` for the repo's default branch HEAD."""
    repo_info = _request(f"https://api.github.com/repos/{owner}/{repo}")
    assert isinstance(repo_info, dict)
    branch = str(repo_info["default_branch"])
    branch_info = _request(
        f"https://api.github.com/repos/{owner}/{repo}/branches/{branch}"
    )
    assert isinstance(branch_info, dict)
    return branch, str(branch_info["commit"]["sha"])


def resolve_github_tag_commit(owner: str, repo: str, tag: str) -> str:
    """Resolve a tag (with or without ``v`` prefix) to a commit SHA."""
    # Try the git refs API directly — this is exact-match and avoids the
    # /commits/{ref} 422 when a ref looks ambiguous.
    for candidate in (tag, f"v{tag}"):
        try:
            data = _request(
                f"https://api.github.com/repos/{owner}/{repo}/git/ref/tags/{candidate}"
            )
        except urllib.error.HTTPError as e:
            if e.code in (404, 422):
                continue
            raise
        if isinstance(data, dict):
            obj = data.get("object", {})
            sha = obj.get("sha")
            if obj.get("type") == "tag" and sha:
                # Annotated tag — dereference to the commit.
                tag_obj = _request(
                    f"https://api.github.com/repos/{owner}/{repo}/git/tags/{sha}"
                )
                if isinstance(tag_obj, dict):
                    return str(tag_obj["object"]["sha"])
            if sha:
                return str(sha)
    raise RuntimeError(f"could not resolve tag {tag!r} on {owner}/{repo}")


def prefetch_github_tree(owner: str, repo: str, rev: str) -> str:
    """Return the SRI ``narHash`` for ``github:owner/repo/rev``."""
    info = nix_flake_prefetch_github(owner, repo, rev)
    # Newer nix exposes "hash" (SRI); older "narHash".
    return info.get("hash") or info["narHash"]
