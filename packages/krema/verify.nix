## Post-refresh build check for nxmanifest: evaluates to whatever this
## package's manifest bump needs to actually build. nxmanifest runs
## `nix-build verify.nix` after a version change and reverts manifest.json if
## it fails, so a bad bump never reaches the rebuild. Opting a package in is
## just a matter of adding this file.
let
    pkgs = import <nixpkgs> { config.allowUnfree = true; };
in
    pkgs.kdePackages.callPackage ./. { }

# <> #
