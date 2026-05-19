{ self }:
{ config, lib, pkgs, ... }:
let
  cfg = config.programs.pi;

  packagePath = pkg: "${pkg}${self.lib.packagePathOf pkg}";

  maybeDefault = self.packages.${pkgs.system}.pi-default-package or null;
  maybeSubagents = self.packages.${pkgs.system}.pi-subagents-package or null;
  maybeIntercom = self.packages.${pkgs.system}.pi-intercom-package or null;
  maybeMcpAdapter = self.packages.${pkgs.system}.pi-mcp-adapter-package or null;
  maybeCustomCompaction = self.packages.${pkgs.system}.pi-custom-compaction-package or null;
  maybeRewindHook = self.packages.${pkgs.system}.pi-rewind-hook-package or null;
  maybeBoomerang = self.packages.${pkgs.system}.pi-boomerang-package or null;
  maybeMemory = self.packages.${pkgs.system}.pi-memory-package or null;
  maybeQmd = self.packages.${pkgs.system}.qmd-package or null;
  maybeRpivAskUserQuestion = self.packages.${pkgs.system}.rpiv-ask-user-question-package or null;

  defaultPiPackages = lib.filter (p: p != null) [
    maybeDefault
    maybeSubagents
    maybeIntercom
    maybeCustomCompaction
    maybeRewindHook
    maybeBoomerang
    maybeMemory
    maybeRpivAskUserQuestion
  ];

  allPiPackages = defaultPiPackages ++ cfg.extraPackages;

  packageEntries = map packagePath (allPiPackages ++ lib.optional (maybeMcpAdapter != null) maybeMcpAdapter);

  baseSettings = {
    packages = packageEntries;
  };

  mergedSettings = lib.recursiveUpdate baseSettings cfg.settings;
in
{
  options.programs.pi = {
    enable = lib.mkEnableOption "pi with repo-managed resources";

    package = lib.mkOption {
      type = lib.types.package;
      default = self.packages.${pkgs.system}.pi;
      description = "Pinned pi package to install.";
    };

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      example = lib.literalExpression "[ inputs.some-pi-packages.packages.${pkgs.system}.default ]";
      description = ''
        Additional pi packages as Nix derivations.

        Contract: each package should expose a pi package root at
        $out/share/pi-packages/<name> (or set passthru.piPackagePath).
      '';
    };

    settings = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = ''
        Extra settings merged into ~/.pi/agent/settings.json.
        Defaults and extraPackages are added to settings.packages automatically.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ] ++ lib.optional (maybeQmd != null) maybeQmd;

    home.file.".pi/agent/settings.json".text = builtins.toJSON mergedSettings;
  };
}
