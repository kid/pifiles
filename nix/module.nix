{ self }:
{ config, lib, pkgs, ... }:
let
  cfg = config.programs.pi;

  packagePath = pkg: "${pkg}${self.lib.packagePathOf pkg}";

  defaultPiPackages =
    let
      maybeDefault = self.packages.${pkgs.system}.pi-default-package or null;
    in
    lib.optional (maybeDefault != null) maybeDefault;

  allPiPackages = defaultPiPackages ++ cfg.extraPackages;

  packageEntries = map packagePath allPiPackages;

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
    home.packages = [ cfg.package ];

    home.file.".pi/agent/settings.json".text = builtins.toJSON mergedSettings;
  };
}
