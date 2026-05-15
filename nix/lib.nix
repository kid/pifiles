{ lib }:
{
  mkPiPackage = {
    pkgs,
    pname,
    version ? "0.1.0",
    src,
  }:
    pkgs.stdenvNoCC.mkDerivation {
      inherit pname version src;

      dontBuild = true;

      installPhase = ''
        runHook preInstall

        pkgRoot="$out/share/pi-packages/${pname}"
        mkdir -p "$pkgRoot"
        cp -R . "$pkgRoot"

        runHook postInstall
      '';

      passthru.piPackagePath = "/share/pi-packages/${pname}";

      meta = {
        description = "Pi package: ${pname}";
        platforms = lib.platforms.all;
      };
    };

  packagePathOf = pkg:
    if pkg ? piPackagePath then
      pkg.piPackagePath
    else if (pkg ? passthru && pkg.passthru ? piPackagePath) then
      pkg.passthru.piPackagePath
    else
      "/share/pi-packages";
}
