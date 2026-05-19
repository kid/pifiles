final: prev: {
  pi = final.callPackage ./pkgs/by-name/pi/package.nix { };

  pifiles-default = final.callPackage ./pkgs/by-name/pifiles-default/package.nix { };
  pi-subagents = final.callPackage ./pkgs/by-name/pi-subagents/package.nix { };
  pi-intercom = final.callPackage ./pkgs/by-name/pi-intercom/package.nix { };
  pi-mcp-adapter = final.callPackage ./pkgs/by-name/pi-mcp-adapter/package.nix { };
  pi-custom-compaction = final.callPackage ./pkgs/by-name/pi-custom-compaction/package.nix { };
  pi-rewind-hook = final.callPackage ./pkgs/by-name/pi-rewind-hook/package.nix { };
  pi-boomerang = final.callPackage ./pkgs/by-name/pi-boomerang/package.nix { };
  pi-memory = final.callPackage ./pkgs/by-name/pi-memory/package.nix { };
  rpiv-ask-user-question = final.callPackage ./pkgs/by-name/rpiv-ask-user-question/package.nix { };

  qmd = final.callPackage ./pkgs/by-name/qmd/package.nix { };

  pi-with-extensions = final.callPackage ./pkgs/by-name/pi-with-extensions/package.nix {
    pi = final.pi;
    qmd = final.qmd;
    extensionPackages = [
      final.pifiles-default
      final.pi-subagents
      final.pi-intercom
      final.pi-mcp-adapter
      final.pi-custom-compaction
      final.pi-rewind-hook
      final.pi-boomerang
      final.pi-memory
      final.rpiv-ask-user-question
    ];
  };
}
