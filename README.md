# pifiles

Nix-first pi setup with pinned extensions.

## Requirements covered

- Flake uses **flake-parts**
- Formatting uses **treefmt**
- Extensions are exposed as Nix packages via a **pkgs-by-name** layout
- Flake exposes an **overlay** containing those packages
- Default app is a `pi` wrapper that passes built extension package roots on CLI (`-e ...`)
- No non-Nix/standalone support
- No user-managed/custom extension loading in wrapper mode

## Structure

- `flake.nix` — flake-parts entrypoint + treefmt config
- `nix/overlay.nix` — overlay exporting all packages
- extension source pinning lives in each `nix/pkgs/by-name/<name>/package.nix`
- `nix/pkgs/by-name/<name>/package.nix` — package definitions (pkgs-by-name pattern), extensions use `buildNpmPackage` and expose a package root with `package.json` and `node_modules/`
- `nix/pkgs/by-name/*/package-lock.json` — vendored npm lockfiles where required

## Upstream packages

`pi` and `qmd` are consumed directly from
[numtide/llm-agents.nix](https://github.com/numtide/llm-agents.nix) (as a flake
input) and are not rebuilt here. Binaries are served from
`https://cache.numtide.com`. To bump them, run `nix flake update llm-agents`.

llm-agents.nix structures each package as a directory under `packages/<name>/`
containing `package.nix` + `hashes.json` + `update.py`. `package.nix` reads
version and hashes from `hashes.json`; `update.py` (a small wrapper over the
shared `scripts/updater/` library) fetches the latest version from npm or
GitHub, computes the new hashes, and rewrites `hashes.json`. A scheduled
GitHub Action discovers updatable packages, runs each `update.py`, and opens
one PR per package.

This repo follows the same pattern for the local extensions:

- `nix/pkgs/by-name/<pkg>/hashes.json` — pins `owner`, `repo`, `version`,
  `rev`, `narHash`, `npmDepsHash`.
- `nix/pkgs/by-name/<pkg>/package.nix` — reads those values via
  `lib.importJSON ./hashes.json`.
- `nix/pkgs/by-name/<pkg>/update.py` — one-liner delegating to
  `scripts/updater/extension.py:main_for`.
- `scripts/updater/` — shared library: GitHub release lookup, `nix flake
prefetch` for narHashes, lockfile regeneration via
  `npm install --package-lock-only --lockfile-version=1` (with backfilled
  integrity for nested deps that ship without it), `npmDepsHash` computation
  via FOD-mismatch parsing.
- `scripts/discover.py` — emits the CI matrix.
- `.github/workflows/update-extensions.yml` — daily cron + manual dispatch;
  one matrix job per extension; opens (or rebases) `update/<pkg>` PRs.

To bump a single extension locally:

```bash
GITHUB_TOKEN=$(gh auth token) ./nix/pkgs/by-name/pi-subagents/update.py
nix build .#pi-subagents
```

## Locally packaged extensions

- `pifiles-default`
- `pi-subagents`
- `pi-intercom`
- `pi-mcp-adapter`
- `pi-custom-compaction`
- `pi-rewind-hook`
- `pi-boomerang`
- `pi-memory`
- `rpiv-ask-user-question`
- `pi-with-extensions` (default; combines upstream `pi` + `qmd` with the
  extensions above)

## Usage

Run the wrapper:

```bash
nix run .
```

Format repo:

```bash
nix fmt
```

Use overlay in another flake (also pulls in `pi`/`qmd` from `llm-agents.nix`):

```nix
{
  inputs.pifiles.url = "github:you/pifiles";

  outputs = { self, nixpkgs, pifiles, ... }: {
    overlays.default = pifiles.overlays.default;
  };
}
```
