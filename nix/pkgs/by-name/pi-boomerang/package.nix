{ buildNpmPackage }:

buildNpmPackage {
  pname = "pi-boomerang";
  version = "0.6.5";
  src = builtins.fetchTree {
    type = "github";
    owner = "nicobailon";
    repo = "pi-boomerang";
    rev = "ea543818f0d3b92bc427e179cfe75d0984553f36";
    narHash = "sha256-qQ2H/m0niMV0WEzdXhh01maTJyUfUod1/EXkHHXcrpM=";
  };

  npmDepsHash = "sha256-x5Jo33O1Pq2yvxFT9foNKjvI4ItH+/Lc92tgbassYuA=";
  dontNpmBuild = true;

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  installPhase = ''
    runHook preInstall

    pkgRoot="$out/share/pi-packages/pi-boomerang"
    mkdir -p "$pkgRoot"
    cp -R . "$pkgRoot"

    mkdir -p "$pkgRoot/node_modules"
    if [ -d node_modules ]; then
      cp -R node_modules/. "$pkgRoot/node_modules"
    fi

    runHook postInstall
  '';

  passthru = {
    piPackagePath = "/share/pi-packages/pi-boomerang";
    extensionDir = "/share/pi-packages/pi-boomerang";
  };
}
