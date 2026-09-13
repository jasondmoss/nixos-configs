## Post-refresh build check for nxmanifest — see packages/krema/verify.nix.
let
    pkgs = import <nixpkgs> { config.allowUnfree = true; };
in
    import ./. { inherit pkgs; }

# <> #
