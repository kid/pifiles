{ pkgs, piVersion ? "0.74.0" }:

pkgs.buildNpmPackage rec {
  pname = "pi-coding-agent";
  version = piVersion;

  src = pkgs.fetchurl {
    url = "https://registry.npmjs.org/@earendil-works/pi-coding-agent/-/pi-coding-agent-${version}.tgz";
    hash = "sha256-l0pzuWGVvX1jDhFYaey14N16XDo47kkm3JlEhmPUo0Q=";
  };

  sourceRoot = "package";

  postPatch = ''
    cp ${./pi-package-lock.json} package-lock.json
  '';

  npmDepsHash = "sha256-vH64sDRZ/r3OR9coPyG4IDTC81i7VIiD1GJ0hYlBakM=";

  dontNpmBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/node_modules/@earendil-works/pi-coding-agent
    cp -R . $out/lib/node_modules/@earendil-works/pi-coding-agent/

    mkdir -p $out/bin
    ln -s $out/lib/node_modules/@earendil-works/pi-coding-agent/dist/cli.js $out/bin/pi

    runHook postInstall
  '';

  meta = with pkgs.lib; {
    description = "pi coding agent";
    homepage = "https://www.npmjs.com/package/@earendil-works/pi-coding-agent";
    license = licenses.mit;
    platforms = platforms.unix;
    mainProgram = "pi";
  };
}
