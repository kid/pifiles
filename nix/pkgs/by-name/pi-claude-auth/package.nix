{ stdenvNoCC, lib }:

let
  hashes = lib.importJSON ./hashes.json;
in
stdenvNoCC.mkDerivation {
  pname = "pi-claude-auth";
  version = hashes.version;

  src = builtins.fetchTree {
    type = "github";
    inherit (hashes)
      owner
      repo
      rev
      narHash
      ;
  };

  installPhase = ''
    runHook preInstall

    pkgRoot="$out/share/pi-packages/pi-claude-auth"
    mkdir -p "$pkgRoot"
    cp -R . "$pkgRoot"

    runHook postInstall
  '';

  passthru = {
    piPackagePath = "/share/pi-packages/pi-claude-auth";
    extensionDir = "/share/pi-packages/pi-claude-auth";
  };
}
