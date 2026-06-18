{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkOption
    mkEnableOption
    types
    literalExpression
    ;

  cfg = config.programs.pi;

  mkPi = pkgs.callPackage ../lib/mk-pi.nix { };

  wrapper = mkPi {
    pi = cfg.package;
    qmd = pkgs.qmd or null;
    name = "pi";
    inherit (cfg)
      extensions
      packages
      prompts
      themes
      systemPrompt
      appendSystemPrompt
      agents
      extraArgs
      ;
    skills = cfg.skills.paths;
    inlineSkills = cfg.skills.inline;
    noExtensions = cfg.pureResources;
    noSkills = cfg.pureResources;
    noPromptTemplates = cfg.pureResources;
    noThemes = cfg.pureResources;
  };

  skillModule = types.submodule (
    { name, ... }:
    {
      options = {
        name = mkOption {
          type = types.str;
          default = name;
          description = "Skill name (frontmatter `name`). Defaults to the attribute name.";
        };
        description = mkOption {
          type = types.str;
          description = "Skill description (frontmatter `description`); determines when pi loads it.";
        };
        text = mkOption {
          type = types.lines;
          description = "Markdown body of the SKILL.md (everything after the frontmatter).";
        };
        extraFiles = mkOption {
          type = types.attrsOf types.path;
          default = { };
          description = "Extra files copied alongside SKILL.md (e.g. scripts, references), keyed by relative path.";
        };
      };
    }
  );
in
{
  options.programs.pi = {
    enable = mkEnableOption "the pi coding agent configured entirely via CLI flags (no settings.json)";

    package = mkOption {
      type = types.package;
      default = pkgs.pi or (throw "programs.pi.package must be set (no pkgs.pi found).");
      defaultText = literalExpression "pkgs.pi";
      description = "Base pi package providing `bin/pi`. The module wraps it with baked CLI flags.";
    };

    finalPackage = mkOption {
      type = types.package;
      readOnly = true;
      description = "Read-only: the wrapped `pi` that the module installs.";
    };

    extensions = mkOption {
      type = types.listOf (types.either types.package types.path);
      default = [ ];
      example = literalExpression "[ pkgs.pi-subagents pkgs.pi-intercom ]";
      description = ''
        Extensions to load via `-e`. Packages must expose an `extensionDir`
        (or `passthru.extensionDir`) attribute; paths/strings are used verbatim.
      '';
    };

    packages = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = literalExpression ''[ "pi-skills" "@org/my-extension" ]'';
      description = "npm/git extension sources loaded via `-e`.";
    };

    skills = {
      inline = mkOption {
        type = types.attrsOf skillModule;
        default = { };
        example = literalExpression ''
          {
            git-helper = {
              description = "Helpers for working with git in this repo.";
              text = "# Git Helper\n\nUse `git ...`";
            };
          }
        '';
        description = "Inline skill definitions; each builds a `<name>/SKILL.md` dir loaded via `--skill`.";
      };

      paths = mkOption {
        type = types.listOf (types.either types.package types.path);
        default = [ ];
        example = literalExpression ''[ "~/.claude/skills" pkgs.my-skill-pack ]'';
        description = "Skill directories or SKILL.md files loaded via `--skill`.";
      };
    };

    systemPrompt = mkOption {
      type = types.nullOr (types.either types.lines types.path);
      default = null;
      description = "Replace pi's default system prompt via `--system-prompt`. String or path.";
    };

    appendSystemPrompt = mkOption {
      type = types.nullOr (types.either types.lines types.path);
      default = null;
      description = "Text appended via `--append-system-prompt`. String or path.";
    };

    agents = mkOption {
      type = types.nullOr (types.either types.lines types.path);
      default = null;
      description = ''
        Global context (the `AGENTS.md` role). There is no CLI flag for it, so
        the content is delivered via `--append-system-prompt` together with
        `appendSystemPrompt`.
      '';
    };

    prompts = mkOption {
      type = types.listOf (types.either types.package types.path);
      default = [ ];
      description = "Prompt-template files or directories loaded via `--prompt-template`.";
    };

    themes = mkOption {
      type = types.listOf (types.either types.package types.path);
      default = [ ];
      description = "Theme files or directories loaded via `--theme`.";
    };

    pureResources = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Add `--no-extensions --no-skills --no-prompt-templates --no-themes` so
        only the resources declared here load, ignoring on-disk discovery.
      '';
    };

    extraArgs = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = literalExpression ''[ "--provider" "anthropic" "--model" "claude-sonnet-4-20250514" ]'';
      description = "Additional CLI arguments appended verbatim (e.g. `--provider`, `--model`, `--theme`).";
    };
  };

  config.programs.pi.finalPackage = lib.mkIf cfg.enable wrapper;
}
