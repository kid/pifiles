{
  mkPi,
  pi,
  qmd,
  extensionPackages ? [ ],
}:
# Pre-configured pi: upstream pi + qmd with a locked-down set of baked-in
# extensions. Built on the shared `mkPi` wrapper builder.
mkPi {
  inherit pi qmd;
  name = "pi-with-extensions";
  extensions = extensionPackages;
  noExtensions = true;
  rejectUserExtensionFlags = true;
}
