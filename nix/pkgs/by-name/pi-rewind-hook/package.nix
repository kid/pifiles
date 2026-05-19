{ buildNpmPackage }:

buildNpmPackage {
  pname = "pi-rewind-hook";
  version = "1.8.4";
  src = builtins.fetchTree {
    type = "github";
    owner = "nicobailon";
    repo = "pi-rewind-hook";
    rev = "684f79a58fb1c30bb2a9605b573b4adf26a56381";
    narHash = "sha256-aDtuZzXVheo+QiVdDDABzEg7UiEyKZirOD9lmnV/o8Q=";
  };

  npmDepsHash = "sha256-9sSTowIK+OvQRYNA+gQDPV6wQo1nZIbfuVee8kBkPZw=";
  dontNpmBuild = true;

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  installPhase = ''
    runHook preInstall

    pkgRoot="$out/share/pi-packages/pi-rewind-hook"
    mkdir -p "$pkgRoot"
    cp -R . "$pkgRoot"

    mkdir -p "$pkgRoot/node_modules"
    if [ -d node_modules ]; then
      cp -R node_modules/. "$pkgRoot/node_modules"
    fi

    runHook postInstall
  '';

  passthru = {
    piPackagePath = "/share/pi-packages/pi-rewind-hook";
    extensionDir = "/share/pi-packages/pi-rewind-hook";
  };
}
