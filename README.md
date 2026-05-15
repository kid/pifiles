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
2. add this repo's default local pi package to `~/.pi/agent/settings.json`

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

- Precedence is defaults first, then `programs.pi.extraPackages` (extra packages win).
- In Nix mode, built-in defaults include flake-pinned local copies of:
  - `nicobailon/pi-subagents`
  - `nicobailon/pi-intercom`
  - `nicobailon/pi-mcp-adapter` (added in filtered mode with `extensions = []`)
  - `nicobailon/pi-custom-compaction`
  - `nicobailon/pi-rewind-hook`
  - `nicobailon/pi-boomerang`
  (no runtime clone/install).
- Collision warnings are not implemented yet (v1 keeps this simple).
