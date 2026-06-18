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
GitHub Action (`.github/workflows/update.yml` + `update-flake.yml`) discovers
updatable packages, runs each `update.py`, and opens a PR per package. We may
adopt the same pattern for the local extensions below (`hashes.json` +
`update.py`) if we want hands-off bumps; for now they remain pinned by hand.

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
