{ buildNpmPackage }:

buildNpmPackage {
  pname = "pi-mcp-adapter";
  version = "2.6.1";
  src = builtins.fetchTree {
    type = "github";
    owner = "nicobailon";
    repo = "pi-mcp-adapter";
    rev = "8c1a28e7ebb837d5fa03de3a67f217ce994782cc";
    narHash = "sha256-jW/vlQ4ay3Le8PRlH3UMYJVhfJYFCxY6frPZCIs/osI=";
  };

  npmDepsHash = "sha256-kQ101vspbdzTYhwt58K+Snbry9WdfHvSNSIsLRW2J4k=";
  dontNpmBuild = true;

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  installPhase = ''
    runHook preInstall

    pkgRoot="$out/share/pi-packages/pi-mcp-adapter"
    mkdir -p "$pkgRoot"
    cp -R . "$pkgRoot"
    mkdir -p "$pkgRoot/node_modules"
    cp -R node_modules/. "$pkgRoot/node_modules"

    runHook postInstall
  '';

  passthru = {
    piPackagePath = "/share/pi-packages/pi-mcp-adapter";
    extensionDir = "/share/pi-packages/pi-mcp-adapter";
  };
}
