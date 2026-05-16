# pifiles

Reproducible pi config repo with:

- **Nix flake** (authoritative pinning)
- **Home Manager module** (`programs.pi.*`)
- **Standalone mode** (Node/npm provided by user)

## What is pinned

- Nix: `flake.lock` + `flake.nix` package pinning
- Standalone: `package-lock.json` for npm resolution
- Current pi CLI pin: `0.74.0`

## Nix usage

### Use the package directly

```bash
nix run .
```

`nix run .` is isolated from your normal Pi packages and local resources.

- It passes the repo's pinned extensions, skills, and prompts explicitly on the command line.
- It disables normal discovery of extensions, skills, prompts, themes, and context files.
- It does not generate or mutate `settings.json` at runtime.
- It still allows ordinary global settings such as model/provider selection.

### Home Manager module

```nix
{
  imports = [ inputs.pifiles.homeManagerModules.default ];

  programs.pi = {
    enable = true;

    # Optional (defaults to this flake's pinned package)
    # package = inputs.pifiles.packages.${pkgs.system}.pi;

    # Add extra pi packages (Nix derivations only)
    extraPackages = [
      # inputs.some-pi-packages.packages.${pkgs.system}.default
    ];

    # Optional settings merged into ~/.pi/agent/settings.json
    settings = {
      # model = "...";
    };
  };
}
```

### Nix pi-package contract

For `programs.pi.extraPackages`, each package should expose a pi package root at:

- `$out/share/pi-packages/<name>`

or define:

- `passthru.piPackagePath = "/share/pi-packages/<name>"`

## Standalone usage

```bash
./scripts/install-standalone.sh
```

This will:

1. `npm ci`
2. patch `pi-memory` for current `@earendil-works/*` package names
3. add this repo's default local pi packages to `~/.pi/agent/settings.json`
4. install local `qmd` at `./node_modules/.bin/qmd`

Then run:

```bash
npx pi
```

## Repo default resources

Default pi package lives at:

- `pi/packages/default`

It includes starter examples for:

- extensions (verify with `/pifiles-ping`)
- skills (example command: `/skill:pifiles-example`)
- prompts (example command: `/pifiles-review`)

## Notes

- `nix run .` is intentionally isolated from global/project package discovery and does not merge in global extensions, skills, prompts, themes, or context files.
- Home Manager mode is different: it manages `~/.pi/agent/settings.json` on purpose.
- Precedence is defaults first, then `programs.pi.extraPackages` (extra packages win).
- In Home Manager / settings-managed Nix mode, built-in defaults include flake-pinned local copies of:
  - `nicobailon/pi-subagents`
  - `nicobailon/pi-intercom`
  - `nicobailon/pi-mcp-adapter`
  - `nicobailon/pi-custom-compaction`
  - `nicobailon/pi-rewind-hook`
  - `nicobailon/pi-boomerang`
  - `jayzeng/pi-memory` (import-rewritten for current `@earendil-works/*` package names)
  - `@juicesharp/rpiv-ask-user-question` (import-rewritten for current `@earendil-works/*` package names)
  - `qmd` (`@tobilu/qmd`, available on PATH for `pi-memory` search)
  (no runtime clone/install).
- Standalone mode also pins `pi-memory` and `qmd` in `package-lock.json`; `npx pi` inherits the local `qmd` binary from `node_modules/.bin`.
- Standalone mode edits `~/.pi/agent/settings.json`; `nix run .` does not.
- The `nix run .` wrapper defaults `PI_OFFLINE=1` to avoid startup network activity unless you explicitly override it.
- Because `nix run .` loads resources explicitly instead of installing packages into settings, `pi list` reflects your normal configured packages, not the repo-pinned `nix run` resource set.
