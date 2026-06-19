{
  description = "Nix-first pi setup with pinned extensions";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    treefmt-nix.url = "github:numtide/treefmt-nix";

    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];

      imports = [
        inputs.treefmt-nix.flakeModule
      ];

      flake = {
        # The overlay only exposes what the modules need: `pi`, `qmd`, the
        # `mkPi` builder, and the `piExtensions` namespace. The pre-configured
        # `pi-with-extensions` is intentionally NOT in the overlay; it is a
        # flake package only (see perSystem below).
        overlays.default = import ./nix/overlays {
          llm-agents = inputs.llm-agents;
        };

        # Declarative pi configuration (extensions / system prompt / skills).
        # Apply `overlays.default` to your pkgs so `pkgs.pi` and
        # `pkgs.piExtensions.*` are available to these modules.
        homeManagerModules = rec {
          pi = ./nix/modules/home-manager.nix;
          default = pi;
        };

        nixosModules = rec {
          pi = ./nix/modules/nixos.nix;
          default = pi;
        };

        darwinModules = rec {
          pi = ./nix/modules/darwin.nix;
          default = pi;
        };
      };

      perSystem =
        {
          system,
          config,
          ...
        }:
        let
          overlay = import ./nix/overlays {
            llm-agents = inputs.llm-agents;
          };
          pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [ overlay ];
          };

          # Pre-configured pi (upstream pi + qmd with a locked-down set of
          # baked-in extensions), built here against the overlaid pkgs rather
          # than in the overlay. Uses the shared `mkPi` builder.
          pi-with-extensions = pkgs.mkPi {
            inherit (pkgs) pi qmd;
            name = "pi-with-extensions";
            extensions = with pkgs.piExtensions; [
              pifiles-default
              pi-subagents
              pi-intercom
              pi-mcp-adapter
              pi-custom-compaction
              pi-memory
              pi-boomerang
              rpiv-ask-user-question
            ];
            noExtensions = true;
          };

          # Expose every extension as an individual flake package.
          extensionPackages = pkgs.lib.filterAttrs (_: pkgs.lib.isDerivation) pkgs.piExtensions;
        in
        {
          packages = {
            inherit (pkgs) pi qmd;
            inherit pi-with-extensions;
            default = pi-with-extensions;
          }
          // extensionPackages;

          apps.default = {
            type = "app";
            program = "${pi-with-extensions}/bin/pi-with-extensions";
          };

          devShells.default = pkgs.mkShell {
            packages = [
              pi-with-extensions
              config.treefmt.build.wrapper
            ];
          };

          checks.pi-module = pkgs.callPackage ./nix/checks/module-test.nix {
            modulePath = ./nix/modules/pi-shared.nix;
          };

          formatter = config.treefmt.build.wrapper;

          treefmt = {
            projectRootFile = "flake.nix";
            programs = {
              nixfmt.enable = true;
              prettier.enable = true;
            };
            settings.formatter.prettier.includes = [
              "**/*.md"
              "**/*.json"
              "**/*.ts"
            ];
          };
        };
    };
}
