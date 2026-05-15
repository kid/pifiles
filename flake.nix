{
  description = "Reproducible pi config (Nix + standalone)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nixpkgs, flake-utils, home-manager, ... }:
    let
      lib = import ./nix/lib.nix { inherit (nixpkgs) lib; };
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
    in
    {
      inherit lib;

      homeManagerModules.default = import ./nix/module.nix {
        inherit self;
      };
    }
    // flake-utils.lib.eachSystem supportedSystems (system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };

        pi = pkgs.callPackage ./nix/pi-cli.nix {
          piVersion = "0.74.0";
        };

        pi-default-package = lib.mkPiPackage {
          inherit pkgs;
          pname = "pifiles-default";
          version = "0.1.0";
          src = ./pi/packages/default;
        };

        defaultPiPackagePath = "${pi-default-package}/share/pi-packages/pifiles-default";

        piWithDefaults = pkgs.writeShellApplication {
          name = "pi-with-defaults";
          runtimeInputs = [
            pi
            pkgs.python3
          ];
          text = ''
            agent_dir="''${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}"
            settings_file="$agent_dir/settings.json"

            mkdir -p "$agent_dir"

            python3 -c '
import json, pathlib, sys
settings_file = pathlib.Path(sys.argv[1])
package_path = sys.argv[2]
if settings_file.exists():
    data = json.loads(settings_file.read_text())
else:
    data = {}
packages = data.get("packages", [])
if not isinstance(packages, list):
    packages = []
# Keep non-string/object entries untouched, but remove stale pifiles-default store paths.
packages = [
    p for p in packages
    if not (isinstance(p, str) and p.endswith("/share/pi-packages/pifiles-default"))
]
packages.append(package_path)
data["packages"] = packages
settings_file.write_text(json.dumps(data, indent=2) + "\n")
' "$settings_file" "${defaultPiPackagePath}"

            exec ${pi}/bin/pi "$@"
          '';
        };
      in
      {
        packages = {
          inherit pi pi-default-package;

          default = piWithDefaults;
        };

        checks = {
          build-pi = pi;
          build-default-package = pi-default-package;
          build-default-wrapper = piWithDefaults;

          smoke-default-package-loading = pkgs.runCommand "smoke-default-package-loading" {
            nativeBuildInputs = [
              piWithDefaults
              pkgs.gnugrep
            ];
          } ''
            export HOME="$TMPDIR/home"
            mkdir -p "$HOME"

            pi-with-defaults list > list.txt
            grep -q 'pifiles-default' list.txt

            cp list.txt "$out"
          '';
        };

        apps.default = {
          type = "app";
          program = "${piWithDefaults}/bin/pi-with-defaults";
          meta = {
            description = "Run pinned pi with repo defaults loaded";
          };
        };

        devShells.default = pkgs.mkShell {
          packages = [
            pi
            pkgs.nodejs
          ];
        };
      });
}
