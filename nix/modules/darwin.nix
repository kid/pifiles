{
  config,
  lib,
  ...
}:
let
  cfg = config.programs.pi;
in
{
  imports = [ ./pi-shared.nix ];

  # All configuration is baked into the wrapped `pi` via CLI flags, so the
  # module only needs to install it system-wide via nix-darwin. No files are
  # written to disk.
  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.finalPackage ];
  };
}
