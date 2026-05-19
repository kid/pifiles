{ buildNpmPackage }:

buildNpmPackage {
  pname = "pi-memory";
  version = "0.3.9";
  src = builtins.fetchTree {
    type = "github";
    owner = "jayzeng";
    repo = "pi-memory";
    rev = "dc144f6a5583499e17cf561105864bf28583764c";
    narHash = "sha256-xxlTEEl7PPlKzG2pin+5LBgtHSqjtotyfOBJ9RDgi9A=";
  };

  npmDepsHash = "sha256-dgo6/de2lbY3Iktf/lUyPkWH5NevRMB59SyjCG4xOnQ=";
  dontNpmBuild = true;

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  installPhase = ''
    runHook preInstall

    pkgRoot="$out/share/pi-packages/pi-memory"
    mkdir -p "$pkgRoot"
    cp -R . "$pkgRoot"

    mkdir -p "$pkgRoot/node_modules"
    if [ -d node_modules ]; then
      cp -R node_modules/. "$pkgRoot/node_modules"
    fi

    find "$pkgRoot" -type f -name '*.ts' -exec \
      sed -i \
        -e 's|@mariozechner/pi-ai|@earendil-works/pi-ai|g' \
        -e 's|@mariozechner/pi-coding-agent|@earendil-works/pi-coding-agent|g' \
        -e 's|@sinclair/typebox|typebox|g' \
        {} +

    runHook postInstall
  '';

  passthru = {
    piPackagePath = "/share/pi-packages/pi-memory";
    extensionDir = "/share/pi-packages/pi-memory";
  };
}
