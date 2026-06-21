# AGENTS.md

Guidance for coding agents (and humans) working in this repo.

## Before declaring work done

Run, and ensure it passes **before** committing / opening a PR:

```sh
nix fmt        # auto-format in place (treefmt: nixfmt + prettier)
nix flake check   # verify formatting + run module test in nix/checks/
```

`nix fmt` applies the treefmt formatters (nixfmt + prettier) in place across the
whole tree (`.nix`, `.md`, `.json`, `.ts`). Run it first so missing trailing
newlines and other formatting drift get fixed automatically, then run
`nix flake check` to verify and run the module test.

A successful `nix build .#<pkg>` is **not** enough — the treefmt check catches
style issues it does not. Run both steps after every file change and again right
before every push (not just the first time you happen to think of it).

## Adding a pi extension

Extensions live one-per-directory under `nix/pkgs/by-name/<name>/`. For a
GitHub-sourced extension the standard set of files is:

- `package.nix` — `buildNpmPackage` + `builtins.fetchTree { type = "github"; ... }`
  pulling from `hashes.json`. Copy the shape from a sibling like
  `nix/pkgs/by-name/pi-subagents/package.nix`.
- `hashes.json` — `owner`, `repo`, `version`, `rev`, `narHash`, `npmDepsHash`.
  Get `narHash` via:
  ```sh
  nix eval --impure --expr \
    '(builtins.fetchTree { type = "github"; owner = "<owner>"; repo = "<repo>"; rev = "<rev>"; }).narHash'
  ```
  Set `npmDepsHash` to `""` first, run `nix build .#<name>`, and copy the
  `sha256-...` value from the fixed-output mismatch error.
- `package-lock.json` — vendored from the upstream repo (used by `postPatch`).

Then:

1. Add the extension to the `extensions = with pkgs.piExtensions; [ ... ]` list
   in `flake.nix` (inside `pi-with-extensions`).
2. List it under "Locally packaged extensions" in `README.md`.
3. `git add nix/pkgs/by-name/<name>/` **before** evaluating the overlay — the
   `by-name` auto-discovery reads tracked files only.
4. Run `nix build .#<name>` and `nix build .#pi-with-extensions`, then
   `nix flake check`.

No edits to `scripts/discover.py` or the CI workflow are needed — the daily
update workflow auto-discovers `by-name/*/hashes.json`.
