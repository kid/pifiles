{
  lib,
  writeShellApplication,
  runCommand,
  writeText,
}:

# Build a `pi` wrapper that bakes configuration in as CLI flags (no
# settings.json). Shared by the home-manager / NixOS module and by the
# repo's pre-configured `pi-config` package.
{
  # Base package providing `bin/pi`.
  pi,
  # Optional companion put on PATH (e.g. qmd).
  qmd ? null,
  # Name of the produced wrapper binary.
  name ? "pi",

  extensions ? [ ], # packages (with extensionDir passthru) or paths -> -e
  packages ? [ ], # npm/git sources -> -e
  skills ? [ ], # dirs / SKILL.md files -> --skill
  inlineSkills ? { }, # attrset: name -> { name?, description, text, extraFiles? }
  prompts ? [ ], # -> --prompt-template
  themes ? [ ], # -> --theme

  systemPrompt ? null, # string or path -> --system-prompt
  appendSystemPrompt ? null, # string or path -> --append-system-prompt
  agents ? null, # string or path, folded into --append-system-prompt

  noExtensions ? false,
  noSkills ? false,
  noPromptTemplates ? false,
  noThemes ? false,

  extraArgs ? [ ], # appended verbatim (e.g. --provider, --model)
}:
let
  inherit (lib)
    optional
    optionals
    concatMap
    concatStringsSep
    escapeShellArg
    ;

  extToSource =
    e:
    if lib.isString e || lib.isPath e then
      toString e
    else if e ? extensionDir then
      "${e}${e.extensionDir}"
    else if e ? passthru && e.passthru ? extensionDir then
      "${e}${e.passthru.extensionDir}"
    else
      throw "mkPi: extension ${e.pname or "package"} has no extensionDir passthru; pass an explicit path instead.";

  mkSkillFile =
    n: skill:
    writeText "skill-${n}.md" ''
      ---
      name: ${skill.name or n}
      description: ${skill.description}
      ---

      ${skill.text}'';

  inlineSkillDir =
    n: skill:
    let
      extra = skill.extraFiles or { };
    in
    runCommand "pi-skill-${n}" { } ''
      mkdir -p "$out/${n}"
      cp ${mkSkillFile n skill} "$out/${n}/SKILL.md"
      ${concatStringsSep "\n" (
        map (fname: ''
          mkdir -p "$(dirname "$out/${n}/${fname}")"
          cp -r ${extra.${fname}} "$out/${n}/${fname}"
        '') (builtins.attrNames extra)
      )}
    '';

  inlineSkillDirs = map (n: toString (inlineSkillDir n inlineSkills.${n})) (
    builtins.attrNames inlineSkills
  );
  skillSources = inlineSkillDirs ++ map toString skills;

  textOf =
    v:
    if v == null then
      null
    else if lib.isPath v || lib.hasPrefix "/" (toString v) then
      builtins.readFile v
    else
      v;

  systemPromptText = textOf systemPrompt;
  appendParts =
    optional (appendSystemPrompt != null) (textOf appendSystemPrompt)
    ++ optional (agents != null) (textOf agents);
  appendText = if appendParts == [ ] then null else concatStringsSep "\n\n" appendParts;

  systemPromptFile =
    if systemPromptText == null then null else writeText "pi-system-prompt" systemPromptText;
  appendPromptFile =
    if appendText == null then null else writeText "pi-append-system-prompt" appendText;

  mkPairs =
    flag: vals:
    concatMap (v: [
      flag
      (escapeShellArg v)
    ]) vals;
  catToken = file: ''"$(cat ${escapeShellArg (toString file)})"'';

  tokens =
    optional noExtensions "--no-extensions"
    ++ optional noSkills "--no-skills"
    ++ optional noPromptTemplates "--no-prompt-templates"
    ++ optional noThemes "--no-themes"
    ++ mkPairs "-e" (map extToSource extensions ++ packages)
    ++ mkPairs "--skill" skillSources
    ++ mkPairs "--prompt-template" (map toString prompts)
    ++ mkPairs "--theme" (map toString themes)
    ++ optionals (systemPromptFile != null) [
      "--system-prompt"
      (catToken systemPromptFile)
    ]
    ++ optionals (appendPromptFile != null) [
      "--append-system-prompt"
      (catToken appendPromptFile)
    ]
    ++ map escapeShellArg extraArgs;

  argLines = concatStringsSep "\n" (map (t: "  " + t) tokens);
in
writeShellApplication {
  inherit name;
  runtimeInputs = [ pi ] ++ optional (qmd != null) qmd;
  text = ''
    export PI_OFFLINE="''${PI_OFFLINE:-1}"
    args=(
    ${argLines}
    )
    exec ${pi}/bin/pi "''${args[@]}" "$@"
  '';
}
