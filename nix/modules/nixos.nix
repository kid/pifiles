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
  # module only needs to install it system-wide. No files are written under
  # /etc and PI_CODING_AGENT_DIR is left untouched.
  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.finalPackage ];
  };
}
