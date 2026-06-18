"""Generate/refresh ``package-lock.json`` for an upstream npm source."""

from __future__ import annotations

import json
import shutil
import subprocess
import tarfile
import tempfile
import urllib.parse
import urllib.request
from pathlib import Path


def _download_github_tarball(owner: str, repo: str, rev: str, dest: Path) -> Path:
    url = f"https://codeload.github.com/{owner}/{repo}/tar.gz/{rev}"
    tarball = dest / "src.tar.gz"
    with urllib.request.urlopen(url, timeout=120) as resp, tarball.open("wb") as fh:
        shutil.copyfileobj(resp, fh)
    with tarfile.open(tarball) as tf:
        tf.extractall(dest)
    # Top-level directory is repo-<rev>
    entries = [p for p in dest.iterdir() if p.is_dir() and p.name != "__pycache__"]
    if len(entries) != 1:
        raise RuntimeError(f"unexpected tarball layout: {entries}")
    return entries[0]


def regenerate_package_lock(
    owner: str,
    repo: str,
    rev: str,
    dest_lockfile: Path,
) -> None:
    """Fetch the upstream source at ``rev`` and write a fresh ``package-lock.json``.

    Prefers any lockfile already present in the upstream tarball; otherwise runs
    ``npm install --package-lock-only`` to generate one.
    """
    if shutil.which("npm") is None:
        raise RuntimeError("npm not found in PATH; install Node.js to update lockfiles")
    with tempfile.TemporaryDirectory(prefix="pifiles-lock-") as tmp:
        src = _download_github_tarball(owner, repo, rev, Path(tmp))
        upstream_lock = src / "package-lock.json"
        # Always regenerate from scratch: upstream lockfiles frequently omit
        # ``resolved``/``integrity`` fields for transitive deps, which makes
        # ``buildNpmPackage``'s fetcher unable to cache them.
        upstream_lock.unlink(missing_ok=True)
        # lockfileVersion=1 matches the format already committed in this repo
        # and reliably populates ``resolved``/``integrity`` for every dep, which
        # ``buildNpmPackage``'s prefetcher requires.
        subprocess.run(
            [
                "npm",
                "install",
                "--package-lock-only",
                "--ignore-scripts",
                "--lockfile-version=1",
            ],
            cwd=src,
            check=True,
        )
        if not upstream_lock.exists():
            raise RuntimeError("npm did not produce a package-lock.json")
        _backfill_missing_integrity(upstream_lock)
        shutil.copyfile(upstream_lock, dest_lockfile)


def _registry_integrity(tarball_url: str) -> str | None:
    """Fetch the SRI ``integrity`` for an npm tarball via the registry API."""
    # Convert e.g. ``https://registry.npmjs.org/@scope/name/-/name-1.2.3.tgz`` to
    # the per-version metadata endpoint and read ``.dist.integrity``.
    parsed = urllib.parse.urlparse(tarball_url)
    if parsed.netloc != "registry.npmjs.org":
        return None
    # Path: /<pkg>/-/<basename>.tgz  (pkg may be scoped, with `/`)
    parts = parsed.path.strip("/").split("/-/")
    if len(parts) != 2:
        return None
    pkg, basename = parts
    # Derive the version from the tarball filename: name-1.2.3.tgz
    if not basename.endswith(".tgz"):
        return None
    stem = basename[:-4]
    # Last `-<semver>` chunk is the version.
    dash = stem.rfind("-")
    if dash == -1:
        return None
    version = stem[dash + 1 :]
    meta_url = f"https://registry.npmjs.org/{pkg}/{version}"
    try:
        with urllib.request.urlopen(meta_url, timeout=30) as resp:
            meta = json.loads(resp.read().decode("utf-8"))
    except Exception:
        return None
    dist = meta.get("dist") if isinstance(meta, dict) else None
    if isinstance(dist, dict) and isinstance(dist.get("integrity"), str):
        return dist["integrity"]
    return None


def _backfill_missing_integrity(lockfile: Path) -> None:
    """Fill in missing ``integrity`` fields for v1 nested deps from the npm registry.

    Some published packages ship an ``npm-shrinkwrap.json`` that omits
    ``integrity`` for nested deps; ``buildNpmPackage`` refuses such lockfiles.
    Recover by fetching the SRI hash from the registry metadata.
    """
    data = json.loads(lockfile.read_text())

    def walk(node: dict) -> int:
        fixed = 0
        deps = node.get("dependencies") if isinstance(node, dict) else None
        if not isinstance(deps, dict):
            return 0
        for _name, entry in deps.items():
            if not isinstance(entry, dict):
                continue
            resolved = entry.get("resolved")
            if (
                isinstance(resolved, str)
                and not resolved.startswith("git+")
                and "integrity" not in entry
            ):
                integrity = _registry_integrity(resolved)
                if integrity:
                    entry["integrity"] = integrity
                    fixed += 1
            fixed += walk(entry)
        return fixed

    fixed = walk(data)
    if fixed:
        lockfile.write_text(json.dumps(data, indent=2) + "\n")
        print(f"Backfilled integrity for {fixed} nested dep(s)")
