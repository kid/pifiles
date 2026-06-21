{ buildNpmPackage, lib }:

let
  hashes = lib.importJSON ./hashes.json;
in
buildNpmPackage {
  pname = "pi-web-access";
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

  inherit (hashes) npmDepsHash;
  dontNpmBuild = true;

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  installPhase = ''
    runHook preInstall

    pkgRoot="$out/share/pi-packages/pi-web-access"
    mkdir -p "$pkgRoot"
    cp -R . "$pkgRoot"

    mkdir -p "$pkgRoot/node_modules"
    if [ -d node_modules ]; then
      cp -R node_modules/. "$pkgRoot/node_modules"
    fi

    runHook postInstall
  '';

  passthru = {
    piPackagePath = "/share/pi-packages/pi-web-access";
    extensionDir = "/share/pi-packages/pi-web-access";
  };
}