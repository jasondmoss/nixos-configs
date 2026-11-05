## Post-refresh build check for nxmanifest (same contract as packages/krema):
## `nix-build verify.nix` must succeed before a manifest bump is accepted.
##
## default.nix is an overlay (self: pkgs:), applied in system/nixpkgs.nix with
## nothing stacked on top of it for phpstorm, so applying it to <nixpkgs> here
## yields the same derivation the rebuild builds and reuses. The build is
## what catches a release whose bundled JCEF/remote-dev libraries need
## dependencies the override does not supply: autoPatchelf fails on them.
let
    pkgs = import <nixpkgs> { config.allowUnfree = true; };
in
    (import ./. pkgs pkgs).phpstorm

# <> #
