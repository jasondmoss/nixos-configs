## Post-refresh build check for nxmanifest (same contract as packages/krema):
## `nix-build verify.nix` must succeed before a manifest bump is accepted.
## update.sh also builds `-A deps` from here to learn the node_modules hash.
let
    pkgs = import <nixpkgs> { config.allowUnfree = true; };
in
    pkgs.callPackage ./. { }

# <> #
