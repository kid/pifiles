{
  buildNpmPackage,
  fetchurl,
  makeWrapper,
  nodejs,
}:

buildNpmPackage {
  pname = "qmd";
  version = "2.1.0";

  src = fetchurl {
    url = "https://registry.npmjs.org/@tobilu/qmd/-/qmd-2.1.0.tgz";
    hash = "sha256-TxsADFudqjb89dBSKNeWb9ffh2B69XL8ozYFl/ZChuY=";
  };

  nativeBuildInputs = [ makeWrapper ];
  npmDepsHash = "sha256-4V2yG6+lQc8dSgMckYIaS7O66Zr3IVG437nkNhawcl8=";
  dontNpmBuild = true;

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  postInstall = ''
    rm -f "$out/bin/qmd"
    makeWrapper ${nodejs}/bin/node "$out/bin/qmd" \
      --add-flags "$out/lib/node_modules/@tobilu/qmd/dist/cli/qmd.js"
  '';
}
