{ buildNpmPackage }:

buildNpmPackage {
  pname = "pifiles-default";
  version = "0.1.0";
  src = ../../../../pi/packages/default;

  npmDepsHash = "sha256-RS2bMVTxxqu9bzqJIc/zK8zp+5olEoylkilRs6Yl+aU=";
  forceEmptyCache = true;
  dontNpmBuild = true;

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  installPhase = ''
    runHook preInstall

    pkgRoot="$out/share/pi-packages/pifiles-default"
    mkdir -p "$pkgRoot"
    cp -R . "$pkgRoot"

    mkdir -p "$pkgRoot/node_modules"
    if [ -d node_modules ]; then
      cp -R node_modules/. "$pkgRoot/node_modules"
    fi

    runHook postInstall
  '';

  passthru = {
    piPackagePath = "/share/pi-packages/pifiles-default";
    extensionDir = "/share/pi-packages/pifiles-default";
  };
}
