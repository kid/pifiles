{ buildNpmPackage }:

buildNpmPackage {
  pname = "rpiv-ask-user-question";
  version = "0.1.4";
  src = builtins.fetchTree {
    type = "github";
    owner = "juicesharp";
    repo = "rpiv-ask-user-question";
    rev = "8dfafc868a412e3cc63f06773b0fbc8c066d5f9f";
    narHash = "sha256-HbvJnDwfWjN5CeStSsIUe+znCOUrdjGmHuxCzG+Wdlg=";
  };

  npmDepsHash = "sha256-tuRFNmmD61GbKUqUzXJ9qRD875gF9GO674jKG8Ax9Ow=";
  dontNpmBuild = true;

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  installPhase = ''
    runHook preInstall

    pkgRoot="$out/share/pi-packages/rpiv-ask-user-question"
    mkdir -p "$pkgRoot"
    cp -R . "$pkgRoot"

    mkdir -p "$pkgRoot/node_modules"
    if [ -d node_modules ]; then
      cp -R node_modules/. "$pkgRoot/node_modules"
    fi

    find "$pkgRoot" -type f -name '*.ts' -exec \
      sed -i \
        -e 's|@mariozechner/pi-coding-agent|@earendil-works/pi-coding-agent|g' \
        -e 's|@mariozechner/pi-tui|@earendil-works/pi-tui|g' \
        -e 's|@sinclair/typebox|typebox|g' \
        {} +

    runHook postInstall
  '';

  passthru = {
    piPackagePath = "/share/pi-packages/rpiv-ask-user-question";
    extensionDir = "/share/pi-packages/rpiv-ask-user-question";
  };
}
