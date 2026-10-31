## Post-refresh build check for nxmanifest (same contract as packages/krema):
## `nix-build verify.nix` must succeed before a manifest bump is accepted.
## pkgs.callPackage, as in system/packages.nix, so the rebuild reuses it.
let
    pkgs = import <nixpkgs> { config.allowUnfree = true; };
in
    pkgs.callPackage ./. { }

# <> #
