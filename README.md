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

## Main packages

- `pi`
- `pifiles-default`
- `pi-subagents`
- `pi-intercom`
- `pi-mcp-adapter`
- `pi-custom-compaction`
- `pi-rewind-hook`
- `pi-boomerang`
- `pi-memory`
- `rpiv-ask-user-question`
- `qmd`
- `pi-with-extensions` (default)

## Usage

Run the wrapper:

```bash
nix run .
```

Format repo:

```bash
nix fmt
```

Use overlay in another flake:

```nix
{
  inputs.pifiles.url = "github:you/pifiles";

  outputs = { self, nixpkgs, pifiles, ... }: {
    overlays.default = pifiles.overlays.default;
  };
}
```
