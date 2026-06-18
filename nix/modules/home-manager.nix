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
  # module only needs to put it on PATH. No files are written to ~/.pi/agent.
  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.finalPackage ];
  };
}
