{ buildNpmPackage }:

buildNpmPackage {
  pname = "pi-custom-compaction";
  version = "0.2.5";
  src = builtins.fetchTree {
    type = "github";
    owner = "nicobailon";
    repo = "pi-custom-compaction";
    rev = "a0e4700badb1c5c1c2dd12eeb250ff067fa67b7e";
    narHash = "sha256-86puorbqlhFwggD4QeNO5vM4IxpqOQQ4r+ulHY7hTE4=";
  };

  npmDepsHash = "sha256-MycDAK5nHPlLjHCDnwst+ogWkCGRSw4FTnsBbwGU/Mc=";
  dontNpmBuild = true;

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  installPhase = ''
    runHook preInstall

    pkgRoot="$out/share/pi-packages/pi-custom-compaction"
    mkdir -p "$pkgRoot"
    cp -R . "$pkgRoot"

    mkdir -p "$pkgRoot/node_modules"
    if [ -d node_modules ]; then
      cp -R node_modules/. "$pkgRoot/node_modules"
    fi

    runHook postInstall
  '';

  passthru = {
    piPackagePath = "/share/pi-packages/pi-custom-compaction";
    extensionDir = "/share/pi-packages/pi-custom-compaction";
  };
}
