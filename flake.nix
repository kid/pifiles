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
    pi-memory = {
      url = "github:jayzeng/pi-memory";
      flake = false;
    };
    rpiv-ask-user-question = {
      url = "github:juicesharp/rpiv-ask-user-question";
      flake = false;
    };
  };

  outputs = inputs@{ self, nixpkgs, flake-utils, home-manager, pi-subagents, pi-intercom, pi-mcp-adapter, pi-custom-compaction, pi-rewind-hook, pi-boomerang, pi-memory, rpiv-ask-user-question, ... }:
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

        pi-memory-package = pkgs.stdenvNoCC.mkDerivation {
          pname = "pi-memory";
          version = "0.3.9";
          src = pi-memory;

          dontBuild = true;

          installPhase = ''
            runHook preInstall

            pkgRoot="$out/share/pi-packages/pi-memory"
            mkdir -p "$pkgRoot"
            cp -R . "$pkgRoot"

            find "$pkgRoot" -type f -name '*.ts' -exec \
              sed -i \
                -e 's|@mariozechner/pi-ai|@earendil-works/pi-ai|g' \
                -e 's|@mariozechner/pi-coding-agent|@earendil-works/pi-coding-agent|g' \
                -e 's|@sinclair/typebox|typebox|g' \
                {} +

            runHook postInstall
          '';

          passthru.piPackagePath = "/share/pi-packages/pi-memory";
        };

        qmd-package = pkgs.buildNpmPackage {
          pname = "qmd";
          version = "2.1.0";

          src = pkgs.fetchurl {
            url = "https://registry.npmjs.org/@tobilu/qmd/-/qmd-2.1.0.tgz";
            hash = "sha256-TxsADFudqjb89dBSKNeWb9ffh2B69XL8ozYFl/ZChuY=";
          };

          nativeBuildInputs = [ pkgs.makeWrapper ];
          npmDepsHash = "sha256-4V2yG6+lQc8dSgMckYIaS7O66Zr3IVG437nkNhawcl8=";
          dontNpmBuild = true;

          postPatch = ''
            cp ${./nix/qmd-package-lock.json} package-lock.json
          '';

          postInstall = ''
            rm -f "$out/bin/qmd"
            makeWrapper ${pkgs.nodejs}/bin/node "$out/bin/qmd" \
              --add-flags "$out/lib/node_modules/@tobilu/qmd/dist/cli/qmd.js"
          '';
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

        pifilesDefaultRoot = "${pi-default-package}/share/pi-packages/pifiles-default";
        piSubagentsRoot = "${pi-subagents-package}/share/pi-packages/pi-subagents";
        piIntercomRoot = "${pi-intercom-package}/share/pi-packages/pi-intercom";
        piCustomCompactionRoot = "${pi-custom-compaction-package}/share/pi-packages/pi-custom-compaction";
        piRewindHookRoot = "${pi-rewind-hook-package}/share/pi-packages/pi-rewind-hook";
        piBoomerangRoot = "${pi-boomerang-package}/share/pi-packages/pi-boomerang";
        piMemoryRoot = "${pi-memory-package}/share/pi-packages/pi-memory";
        rpivAskUserQuestionRoot = "${rpiv-ask-user-question-package}/share/pi-packages/rpiv-ask-user-question";

        extensionPaths = [
          "${pifilesDefaultRoot}/extensions/hello.ts"
          "${piSubagentsRoot}/src/extension/index.ts"
          "${piIntercomRoot}/index.ts"
          "${piCustomCompactionRoot}/index.ts"
          "${piRewindHookRoot}/index.ts"
          "${piBoomerangRoot}/index.ts"
          "${piMemoryRoot}/index.ts"
          "${rpivAskUserQuestionRoot}/index.ts"
        ];

        skillPaths = [
          "${pifilesDefaultRoot}/skills"
          "${piSubagentsRoot}/skills"
          "${piIntercomRoot}/skills"
        ];

        promptTemplatePaths = [
          "${pifilesDefaultRoot}/prompts"
          "${piSubagentsRoot}/prompts"
        ];

        extensionArgs = builtins.concatStringsSep " " (map (p: "-e \"${p}\"") extensionPaths);
        skillArgs = builtins.concatStringsSep " " (map (p: "--skill \"${p}\"") skillPaths);
        promptTemplateArgs = builtins.concatStringsSep " " (map (p: "--prompt-template \"${p}\"") promptTemplatePaths);

        piWithDefaults = pkgs.writeShellApplication {
          name = "pi-with-defaults";
          runtimeInputs = [
            pi
            qmd-package
          ];
          text = ''
            export PI_OFFLINE="''${PI_OFFLINE:-1}"

            case "''${1:-}" in
              install|remove|uninstall|update|list|config)
                echo "pi package-management commands are disabled in nix-run mode." >&2
                echo "This wrapper loads pinned resources explicitly and does not use settings-installed packages." >&2
                exit 2
                ;;
            esac

            exec ${pi}/bin/pi \
              --no-extensions \
              --no-skills \
              --no-prompt-templates \
              --no-themes \
              --no-context-files \
              ${extensionArgs} \
              ${skillArgs} \
              ${promptTemplateArgs} \
              "$@"
          '';
        };
      in
      {
        packages = {
          inherit pi pi-default-package pi-subagents-package pi-intercom-package pi-mcp-adapter-package pi-custom-compaction-package pi-rewind-hook-package pi-boomerang-package pi-memory-package qmd-package rpiv-ask-user-question-package;

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
          build-memory-package = pi-memory-package;
          build-qmd-package = qmd-package;
          build-rpiv-ask-user-question-package = rpiv-ask-user-question-package;
          build-default-wrapper = piWithDefaults;

          smoke-default-package-loading = pkgs.runCommand "smoke-default-package-loading" {
            nativeBuildInputs = [
              pkgs.nodejs
              qmd-package
            ];
          } ''
            export HOME="$TMPDIR/home"
            mkdir -p "$HOME"

            node --input-type=module <<'EOF' > result.txt
            import { DefaultResourceLoader } from 'file://${pi}/lib/node_modules/@earendil-works/pi-coding-agent/dist/core/resource-loader.js';

            const loader = new DefaultResourceLoader({
              cwd: process.cwd(),
              agentDir: process.env.TMPDIR + '/agent',
              noExtensions: true,
              noSkills: true,
              noPromptTemplates: true,
              noThemes: true,
              noContextFiles: true,
              additionalExtensionPaths: ${builtins.toJSON extensionPaths},
              additionalSkillPaths: ${builtins.toJSON skillPaths},
              additionalPromptTemplatePaths: ${builtins.toJSON promptTemplatePaths},
            });

            await loader.reload();

            const skillNames = loader.getSkills().skills.map((s) => s.name).sort();
            const promptNames = loader.getPrompts().prompts.map((p) => p.name).sort();
            const extensionCount = loader.getExtensions().extensions.length;
            const extensionErrors = loader.getExtensions().errors.length;

            const requiredSkills = ['pi-intercom', 'pi-subagents', 'pifiles-example'];
            const requiredPrompts = [
              'gather-context-and-clarify',
              'parallel-cleanup',
              'parallel-context-build',
              'parallel-handoff-plan',
              'parallel-research',
              'parallel-review',
              'pifiles-review',
              'review-loop',
            ];

            for (const name of requiredSkills) {
              if (!skillNames.includes(name)) throw new Error('missing skill: ' + name);
            }
            for (const name of requiredPrompts) {
              if (!promptNames.includes(name)) throw new Error('missing prompt: ' + name);
            }
            if (extensionCount !== 8) throw new Error('expected 8 extensions, got ' + extensionCount);
            if (extensionErrors !== 0) throw new Error('expected 0 extension errors, got ' + extensionErrors);

            console.log(JSON.stringify({ skillNames, promptNames, extensionCount }, null, 2));
            EOF

            qmd --version >/dev/null
            test ! -e "$HOME/.pi/agent/settings.json"

            cp result.txt "$out"
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
            qmd-package
          ];
        };
      });
}
