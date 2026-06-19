{
  lib,
  runCommand,
  bash,
  modulePath,
  pkgs,
}:
let
  # Evaluate the shared module against a representative configuration and grab
  # the wrapped `pi` it produces.
  eval = lib.evalModules {
    modules = [
      modulePath
      {
        _module.args.pkgs = pkgs;
        programs.pi = {
          enable = true;
          extensions = [ pkgs.piExtensions.pi-subagents ];
          packages = [ "pi-skills" ];
          systemPrompt = "Test system prompt.";
          appendSystemPrompt = "Be concise.";
          agents = "# Global\nPrefer rg.";
          skills.inline.demo = {
            description = "demo skill";
            text = "# Demo\nUse it.";
          };
          pureResources = true;
          extraArgs = [
            "--provider"
            "anthropic"
          ];
        };
      }
    ];
  };
  wrapper = eval.config.programs.pi.finalPackage;
in
runCommand "pi-module-test" { } ''
  script=${wrapper}/bin/pi
  echo "==> wrapper script:"
  cat "$script"

  echo "==> bash syntax check"
  ${bash}/bin/bash -n "$script"

  echo "==> expected CLI flags present"
  for needle in \
    '--no-extensions' '--no-skills' '--no-prompt-templates' '--no-themes' \
    'pi-subagents' 'pi-skills' '--skill' \
    '--system-prompt' '--append-system-prompt' '--provider'; do
    grep -qF -- "$needle" "$script" || { echo "MISSING: $needle" >&2; exit 1; }
  done

  echo "==> NO settings.json is referenced anywhere"
  if grep -qF 'settings.json' "$script"; then
    echo "wrapper unexpectedly references settings.json" >&2; exit 1
  fi

  echo "==> inline skill built correctly"
  skilldir=$(grep -oE '/nix/store/[^ ]*-pi-skill-demo' "$script" | head -1)
  test -f "$skilldir/demo/SKILL.md"
  grep -qF 'name: demo' "$skilldir/demo/SKILL.md"
  grep -qF 'description: demo skill' "$skilldir/demo/SKILL.md"

  echo "==> agents folded into the append-system-prompt file"
  appendfile=$(grep -oE '/nix/store/[^ )]*-pi-append-system-prompt' "$script" | head -1)
  grep -qF 'Be concise.' "$appendfile"
  grep -qF 'Prefer rg.' "$appendfile"

  echo "all module checks passed"
  touch $out
''
