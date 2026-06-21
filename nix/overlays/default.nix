{ llm-agents }:
final: _prev:
let
  inherit (final) lib;
  upstream = llm-agents.packages.${final.stdenv.hostPlatform.system};

  # Auto-discover extension packages: every package directory under
  # ./pkgs/by-name. That folder holds extensions only (pi-config lives
  # outside it, as a flake-only package), so no per-name listing is needed.
  byNameDir = ../pkgs/by-name;
  extensionNames = lib.attrNames (
    lib.filterAttrs (
      name: type: type == "directory" && builtins.pathExists (byNameDir + "/${name}/package.nix")
    ) (builtins.readDir byNameDir)
  );
in
{
  # Provided by numtide/llm-agents.nix (auto-updated upstream)
  pi = upstream.pi;
  qmd = upstream.qmd;

  # Shared builder for configured `pi` wrappers. Consumed by the
  # home-manager / NixOS / nix-darwin modules and by the (flake-only)
  # pi-config package.
  mkPi = final.callPackage ../lib/mk-pi.nix { };

  # Pi extensions packaged locally (not yet in llm-agents.nix), grouped under a
  # single namespace à la `pkgs.vimPlugins`. Reference them as e.g.
  # `pkgs.piExtensions.pi-subagents`.
  piExtensions = lib.recurseIntoAttrs (
    lib.genAttrs extensionNames (name: final.callPackage (byNameDir + "/${name}/package.nix") { })
  );
}
