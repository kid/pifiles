{ buildNpmPackage }:

buildNpmPackage {
  pname = "pi-subagents";
  version = "0.24.3";
  src = builtins.fetchTree {
    type = "github";
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "e99bf5b84dc543012e2e4dee2478d6f914a37b27";
    narHash = "sha256-giJ9SUjWz7qAInYZBijPOQSNjdEOtysLCf11rht2Gf8=";
  };

  npmDepsHash = "sha256-hwpaATdncPlomOeKNtg3bky01Pzou+HD2VuAmD9o6QI=";
  dontNpmBuild = true;

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  installPhase = ''
    runHook preInstall

    pkgRoot="$out/share/pi-packages/pi-subagents"
    mkdir -p "$pkgRoot"
    cp -R . "$pkgRoot"

    mkdir -p "$pkgRoot/node_modules"
    if [ -d node_modules ]; then
      cp -R node_modules/. "$pkgRoot/node_modules"
    fi

    runHook postInstall
  '';

  passthru = {
    piPackagePath = "/share/pi-packages/pi-subagents";
    extensionDir = "/share/pi-packages/pi-subagents";
  };
}
