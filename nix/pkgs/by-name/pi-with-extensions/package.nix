{
  writeShellApplication,
  lib,
  pi,
  qmd,
  extensionPackages ? [ ],
}:
let
  extensionArgs = lib.concatStringsSep " \\\n      " (
    map (
      pkg:
      let
        extensionDir =
          if pkg ? extensionDir then
            pkg.extensionDir
          else if pkg ? passthru && pkg.passthru ? extensionDir then
            pkg.passthru.extensionDir
          else
            throw "missing extensionDir passthru on ${pkg.pname or "unknown package"}";
      in
      "-e \"${pkg}${extensionDir}\""
    ) extensionPackages
  );
in
writeShellApplication {
  name = "pi-with-extensions";
  runtimeInputs = [
    pi
    qmd
  ];

  text = ''
    export PI_OFFLINE="''${PI_OFFLINE:-1}"

    for arg in "$@"; do
      case "$arg" in
        -e|--extension|--extensions)
          echo "Custom extensions are disabled in this Nix wrapper." >&2
          exit 2
          ;;
      esac
    done

    exec ${pi}/bin/pi \
      --no-extensions \
      ${extensionArgs} \
      "$@"
  '';
}
