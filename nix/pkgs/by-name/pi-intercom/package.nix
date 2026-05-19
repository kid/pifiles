{ buildNpmPackage }:

buildNpmPackage {
  pname = "pi-intercom";
  version = "0.6.0";
  src = builtins.fetchTree {
    type = "github";
    owner = "nicobailon";
    repo = "pi-intercom";
    rev = "5caa4aa1bd060cf0aebbf1a5dfbb1abb6e23e457";
    narHash = "sha256-cYh7zsSbDqsq5JpNQbAZFGS/beRN7oh/KuTN3QQZn34=";
  };

  npmDepsHash = "sha256-YhEyowXNFda+Y+gKLYCejCOub1NElOa3m4mC+D4Q+B8=";
  dontNpmBuild = true;

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  installPhase = ''
    runHook preInstall

    pkgRoot="$out/share/pi-packages/pi-intercom"
    mkdir -p "$pkgRoot"
    cp -R . "$pkgRoot"

    mkdir -p "$pkgRoot/node_modules"
    if [ -d node_modules ]; then
      cp -R node_modules/. "$pkgRoot/node_modules"
    fi

    runHook postInstall
  '';

  passthru = {
    piPackagePath = "/share/pi-packages/pi-intercom";
    extensionDir = "/share/pi-packages/pi-intercom";
  };
}
