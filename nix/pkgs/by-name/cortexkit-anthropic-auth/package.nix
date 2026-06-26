{ buildNpmPackage, lib }:

let
  hashes = lib.importJSON ./hashes.json;
in
buildNpmPackage {
  pname = "cortexkit-anthropic-auth";
  version = hashes.version;

  src = builtins.fetchTree {
    type = "github";
    inherit (hashes)
      owner
      repo
      rev
      narHash
      ;
  };

  npmDepsHash = "sha256-H+MISv1lYqA/qRkoUtOOlxxAP9QsVXNONxXJZH+YRbc=";
  dontNpmBuild = true;
  makeCacheWritable = true;
  npmFlags = [ "--legacy-peer-deps" ];

  postPatch = ''
    cp ${./package.json} package.json
    cp ${./package-lock.json} package-lock.json
    chmod u+w package.json package-lock.json
  '';

  # We don't need the whole monorepo — just install the pi package
  # from npm with its deps, then copy the dist to the output.
  installPhase = ''
    runHook preInstall

    pkgRoot="$out/share/pi-packages/cortexkit-anthropic-auth"
    mkdir -p "$pkgRoot/dist" "$pkgRoot/node_modules"

    # Copy the pi package's dist
    cp -R node_modules/@cortexkit/pi-anthropic-auth/dist/. "$pkgRoot/dist"
    cp node_modules/@cortexkit/pi-anthropic-auth/package.json "$pkgRoot/package.json"

    # Copy all node_modules for runtime resolution
    cp -R node_modules/. "$pkgRoot/node_modules"

    runHook postInstall
  '';

  passthru = {
    piPackagePath = "/share/pi-packages/cortexkit-anthropic-auth";
    extensionDir = "/share/pi-packages/cortexkit-anthropic-auth";
  };
}
