# pifiles

Nix-first pi setup with pinned extensions.

## Requirements covered

- Flake uses **flake-parts**
- Formatting uses **treefmt**
- Extensions are exposed under a single **`piExtensions`** namespace (à la
  `pkgs.vimPlugins`)
- The **overlay** only exposes what the modules need: `pi`, `qmd`, `mkPi`, and
  `piExtensions`
- `pi-config` is a **flake package only** (not in the overlay)
- Default app is a `pi` wrapper that passes built extension package roots on CLI (`-e ...`)
- No non-Nix/standalone support
- No user-managed/custom extension loading in wrapper mode

## Structure

- `flake.nix` — flake-parts entrypoint + treefmt config; builds the flake-only
  `pi-config` package and re-exports each extension flatly
- `nix/overlays/` — overlay directory (`default.nix`), imported as
  `import ./nix/overlays`. Exposes `pi`, `qmd`, `mkPi`, and the `piExtensions`
  namespace (nothing else). Extensions are **auto-discovered** from the
  directories under `nix/pkgs/by-name/` — no per-name listing.
- the flake-only pre-configured `pi-config` is defined inline in
  `flake.nix` (via `pkgs.mkPi`), so `by-name/` contains extensions only
- `nix/lib/mk-pi.nix` — shared builder that wraps a base `pi` with baked-in CLI
  flags (extensions/skills/prompts/themes/system prompt). Used by both
  `pi-config` and the home-manager / NixOS / nix-darwin modules so they
  share one code path.
- `nix/modules/` — `pi-shared.nix` (options) + `home-manager.nix` / `nixos.nix`
  / `darwin.nix`
- `nix/checks/module-test.nix` — `nix flake check` test for the module/builder
- `nix/pkgs/by-name/<name>/package.nix` — one directory per extension
  (extensions only); each uses `buildNpmPackage` and exposes a package root with
  `package.json` and `node_modules/`. Adding a directory here automatically adds
  it to `piExtensions` (and the flake packages) — no other edits required.
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

Grouped under `pkgs.piExtensions` (overlay) and re-exported as flat flake
packages:

- `piExtensions.pifiles-default`
- `piExtensions.pi-subagents`
- `piExtensions.pi-intercom`
- `piExtensions.pi-mcp-adapter`
- `piExtensions.pi-custom-compaction`
- `piExtensions.pi-rewind-hook`
- `piExtensions.pi-boomerang`
- `piExtensions.pi-memory`
- `piExtensions.rpiv-ask-user-question`
- `piExtensions.pi-web-access`
- `piExtensions.pi-claude-auth`

Plus the flake-only `pi-config` (default package; combines upstream
`pi` + `qmd` with a baked-in set of the extensions above).

## Home Manager / NixOS / nix-darwin module

The flake exposes `homeManagerModules.default`, `nixosModules.default`, and
`darwinModules.default` for declaratively configuring pi (extensions, system
prompt, skills). Apply `overlays.default` so `pkgs.pi` and the extension
packages are available. All three share the same `programs.pi` options.

**No `settings.json` is generated.** The module builds a wrapped `pi` that bakes
everything in as CLI flags (`-e`, `--skill`, `--prompt-template`, `--theme`,
`--system-prompt`, `--append-system-prompt`, ...) and installs that on PATH. The
only thing installed is the wrapper — nothing is written to `~/.pi/agent` or
`/etc`, so there are no trust or writability concerns.

### Home Manager

```nix
{
  inputs.pifiles.url = "github:you/pifiles";

  # in your home configuration:
  imports = [ inputs.pifiles.homeManagerModules.default ];

  nixpkgs.overlays = [ inputs.pifiles.overlays.default ];

  programs.pi = {
    enable = true;
    package = pkgs.pi; # base package providing bin/pi
    extensions = [ pkgs.piExtensions.pi-subagents pkgs.piExtensions.pi-intercom ]; # -> -e <path>
    packages = [ "pi-skills" ]; # npm/git sources -> -e <name>

    systemPrompt = "You are a focused, concise engineer."; # --system-prompt
    appendSystemPrompt = "Always run `nix fmt` before finishing."; # --append-system-prompt
    agents = ''
      # Global instructions
      Prefer ripgrep. Keep diffs small.
    ''; # no CLI flag exists -> folded into --append-system-prompt

    skills = {
      # Inline skills build <name>/SKILL.md dirs loaded via --skill.
      inline.git-helper = {
        description = "Helpers for git workflows in this repo. Use for commits, rebases.";
        text = ''
          # Git Helper
          Use conventional commits.
        '';
        # extraFiles = { "scripts/foo.sh" = ./foo.sh; }; # optional
      };
      # Existing skill dirs / SKILL.md files -> --skill <path>.
      paths = [ "~/.claude/skills" ];
    };

    pureResources = true; # add --no-extensions/--no-skills/... to ignore discovery

    # Anything without a dedicated option (model, provider, theme name, ...)
    # is passed verbatim:
    extraArgs = [ "--provider" "anthropic" "--model" "claude-sonnet-4-20250514" ];
  };
}
```

### NixOS

```nix
{
  imports = [ inputs.pifiles.nixosModules.default ];
  nixpkgs.overlays = [ inputs.pifiles.overlays.default ];

  programs.pi = {
    enable = true;
    package = pkgs.pi;
    extensions = [ pkgs.piExtensions.pi-subagents ];
    systemPrompt = "You are a careful systems engineer.";
    extraArgs = [ "--provider" "anthropic" ];
  };
}
```

Installs the wrapped `pi` into `environment.systemPackages`.

### nix-darwin

Identical to NixOS — import `inputs.pifiles.darwinModules.default` and use the
same `programs.pi` options; it installs the wrapper into
`environment.systemPackages`.

### Module options

| Option                           | Description                                                         |
| -------------------------------- | ------------------------------------------------------------------- |
| `programs.pi.enable`             | Enable the module.                                                  |
| `programs.pi.package`            | Base pi package providing `bin/pi` (default `pkgs.pi`).             |
| `programs.pi.finalPackage`       | Read-only: the wrapped `pi` that gets installed.                    |
| `programs.pi.extensions`         | Extension packages (need `extensionDir` passthru) or paths -> `-e`. |
| `programs.pi.packages`           | npm/git extension sources -> `-e`.                                  |
| `programs.pi.systemPrompt`       | Replace system prompt -> `--system-prompt`; string or path.         |
| `programs.pi.appendSystemPrompt` | Append -> `--append-system-prompt`; string or path.                 |
| `programs.pi.agents`             | Global context, delivered via `--append-system-prompt`.             |
| `programs.pi.skills.inline`      | Inline skills -> `<name>/SKILL.md` via `--skill`.                   |
| `programs.pi.skills.paths`       | Skill dirs / SKILL.md files -> `--skill`.                           |
| `programs.pi.prompts`            | Prompt-template files/dirs -> `--prompt-template`.                  |
| `programs.pi.themes`             | Theme files/dirs -> `--theme`.                                      |
| `programs.pi.pureResources`      | Add `--no-extensions/--no-skills/...` to ignore discovery.          |
| `programs.pi.extraArgs`          | Extra CLI args appended verbatim (`--provider`, `--model`, ...).    |

## Usage

Run the wrapper:

```bash
nix run .
```

Format repo:

```bash
nix fmt
```

Use overlay in another flake (also pulls in `pi`/`qmd` from `llm-agents.nix`).
The overlay adds `pkgs.pi`, `pkgs.qmd`, `pkgs.mkPi`, and the
`pkgs.piExtensions.*` namespace:

```nix
{
  inputs.pifiles.url = "github:you/pifiles";

  outputs = { self, nixpkgs, pifiles, ... }: {
    overlays.default = pifiles.overlays.default;
    # e.g. pkgs.piExtensions.pi-subagents, pkgs.mkPi { ... }
  };
}
```

`pi-config` is not part of the overlay; consume it from the flake
packages output (`pifiles.packages.<system>.pi-config`).
