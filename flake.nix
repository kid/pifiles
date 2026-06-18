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
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      imports = [
        inputs.treefmt-nix.flakeModule
      ];

      flake = {
        overlays.default = import ./nix/overlay.nix {
          llm-agents = inputs.llm-agents;
        };
      };

      perSystem =
        {
          system,
          config,
          ...
        }:
        let
          overlay = import ./nix/overlay.nix {
            llm-agents = inputs.llm-agents;
          };
          pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [ overlay ];
          };
        in
        {
          packages = {
            inherit (pkgs)
              pi
              pifiles-default
              pi-subagents
              pi-intercom
              pi-mcp-adapter
              pi-custom-compaction
              pi-rewind-hook
              pi-boomerang
              pi-memory
              rpiv-ask-user-question
              qmd
              pi-with-extensions
              ;

            default = pkgs.pi-with-extensions;
          };

          apps.default = {
            type = "app";
            program = "${pkgs.pi-with-extensions}/bin/pi-with-extensions";
          };

          devShells.default = pkgs.mkShell {
            packages = [
              pkgs.pi-with-extensions
              config.treefmt.build.wrapper
            ];
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
