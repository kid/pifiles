{
  description = "Reproducible pi config (Nix + standalone)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    pi-subagents = {
      url = "github:nicobailon/pi-subagents";
      flake = false;
    };
    pi-intercom = {
      url = "github:nicobailon/pi-intercom";
      flake = false;
    };
    pi-mcp-adapter = {
      url = "github:nicobailon/pi-mcp-adapter";
      flake = false;
    };
    pi-custom-compaction = {
      url = "github:nicobailon/pi-custom-compaction";
      flake = false;
    };
    pi-rewind-hook = {
      url = "github:nicobailon/pi-rewind-hook";
      flake = false;
    };
    pi-boomerang = {
      url = "github:nicobailon/pi-boomerang";
      flake = false;
    };
    rpiv-ask-user-question = {
      url = "github:juicesharp/rpiv-ask-user-question";
      flake = false;
    };
  };

  outputs = inputs@{ self, nixpkgs, flake-utils, home-manager, pi-subagents, pi-intercom, pi-mcp-adapter, pi-custom-compaction, pi-rewind-hook, pi-boomerang, rpiv-ask-user-question, ... }:
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

        pi-subagents-package = lib.mkPiPackage {
          inherit pkgs;
          pname = "pi-subagents";
          version = "0.24.3";
          src = pi-subagents;
        };

        pi-intercom-package = lib.mkPiPackage {
          inherit pkgs;
          pname = "pi-intercom";
          version = "0.6.0";
          src = pi-intercom;
        };

        pi-mcp-adapter-package = lib.mkPiPackage {
          inherit pkgs;
          pname = "pi-mcp-adapter";
          version = "2.6.1";
          src = pi-mcp-adapter;
        };

        pi-custom-compaction-package = lib.mkPiPackage {
          inherit pkgs;
          pname = "pi-custom-compaction";
          version = "0.2.5";
          src = pi-custom-compaction;
        };

        pi-rewind-hook-package = lib.mkPiPackage {
          inherit pkgs;
          pname = "pi-rewind-hook";
          version = "1.8.4";
          src = pi-rewind-hook;
        };

        pi-boomerang-package = lib.mkPiPackage {
          inherit pkgs;
          pname = "pi-boomerang";
          version = "0.6.5";
          src = pi-boomerang;
        };

        rpiv-ask-user-question-package = pkgs.stdenvNoCC.mkDerivation {
          pname = "rpiv-ask-user-question";
          version = "0.1.4";
          src = rpiv-ask-user-question;

          dontBuild = true;

          installPhase = ''
            runHook preInstall

            pkgRoot="$out/share/pi-packages/rpiv-ask-user-question"
            mkdir -p "$pkgRoot"
            cp -R . "$pkgRoot"

            find "$pkgRoot" -type f -name '*.ts' -exec \
              sed -i \
                -e 's|@mariozechner/pi-coding-agent|@earendil-works/pi-coding-agent|g' \
                -e 's|@mariozechner/pi-tui|@earendil-works/pi-tui|g' \
                -e 's|@sinclair/typebox|typebox|g' \
                {} +

            runHook postInstall
          '';

          passthru.piPackagePath = "/share/pi-packages/rpiv-ask-user-question";
        };

        mcpAdapterPackagePath = "${pi-mcp-adapter-package}/share/pi-packages/pi-mcp-adapter";

        defaultPackagePaths = [
          "${pi-default-package}/share/pi-packages/pifiles-default"
          "${pi-subagents-package}/share/pi-packages/pi-subagents"
          "${pi-intercom-package}/share/pi-packages/pi-intercom"
          "${pi-custom-compaction-package}/share/pi-packages/pi-custom-compaction"
          "${pi-rewind-hook-package}/share/pi-packages/pi-rewind-hook"
          "${pi-boomerang-package}/share/pi-packages/pi-boomerang"
          "${rpiv-ask-user-question-package}/share/pi-packages/rpiv-ask-user-question"
        ];

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
default_paths = sys.argv[2:-1]
mcp_adapter_path = sys.argv[-1]
if settings_file.exists():
    data = json.loads(settings_file.read_text())
else:
    data = {}
packages = data.get("packages", [])
if not isinstance(packages, list):
    packages = []
# Keep non-string/object entries untouched, but remove stale forms for built-in packages.
legacy = {
    "git:github.com/nicobailon/pi-subagents",
    "nicobailon/pi-subagents",
    "git:github.com/nicobailon/pi-intercom",
    "nicobailon/pi-intercom",
    "git:github.com/nicobailon/pi-mcp-adapter",
    "nicobailon/pi-mcp-adapter",
    "git:github.com/nicobailon/pi-custom-compaction",
    "nicobailon/pi-custom-compaction",
    "git:github.com/nicobailon/pi-rewind-hook",
    "nicobailon/pi-rewind-hook",
    "git:github.com/nicobailon/pi-boomerang",
    "nicobailon/pi-boomerang",
    "git:github.com/juicesharp/rpiv-ask-user-question",
    "@juicesharp/rpiv-ask-user-question",
}
suffixes = (
    "/share/pi-packages/pifiles-default",
    "/share/pi-packages/pi-subagents",
    "/share/pi-packages/pi-intercom",
    "/share/pi-packages/pi-mcp-adapter",
    "/share/pi-packages/pi-custom-compaction",
    "/share/pi-packages/pi-rewind-hook",
    "/share/pi-packages/pi-boomerang",
    "/share/pi-packages/rpiv-ask-user-question",
)
def is_stale(entry):
    if isinstance(entry, str):
        return entry in legacy or any(entry.endswith(s) for s in suffixes)
    if isinstance(entry, dict):
        source = entry.get("source")
        return isinstance(source, str) and (
            source in legacy or any(source.endswith(s) for s in suffixes)
        )
    return False

packages = [p for p in packages if not is_stale(p)]
packages.extend(default_paths)
packages.append({"source": mcp_adapter_path, "extensions": []})
data["packages"] = packages
settings_file.write_text(json.dumps(data, indent=2) + "\n")
' "$settings_file" ${builtins.concatStringsSep " " (map (p: "\"${p}\"") defaultPackagePaths)} "${mcpAdapterPackagePath}"

            exec ${pi}/bin/pi "$@"
          '';
        };
      in
      {
        packages = {
          inherit pi pi-default-package pi-subagents-package pi-intercom-package pi-mcp-adapter-package pi-custom-compaction-package pi-rewind-hook-package pi-boomerang-package rpiv-ask-user-question-package;

          default = piWithDefaults;
        };

        checks = {
          build-pi = pi;
          build-default-package = pi-default-package;
          build-subagents-package = pi-subagents-package;
          build-intercom-package = pi-intercom-package;
          build-mcp-adapter-package = pi-mcp-adapter-package;
          build-custom-compaction-package = pi-custom-compaction-package;
          build-rewind-hook-package = pi-rewind-hook-package;
          build-boomerang-package = pi-boomerang-package;
          build-rpiv-ask-user-question-package = rpiv-ask-user-question-package;
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
            grep -q 'pi-subagents' list.txt
            grep -q 'pi-intercom' list.txt
            grep -q 'pi-mcp-adapter' list.txt
            grep -q 'pi-custom-compaction' list.txt
            grep -q 'pi-rewind-hook' list.txt
            grep -q 'pi-boomerang' list.txt
            grep -q 'rpiv-ask-user-question' list.txt

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
