let
    pkgs = import <nixpkgs> {
        localSystem = {
            gcc.arch = "alderlake";
            gcc.tune = "alderlake";
            system = "x86_64-linux";
        };
    };
in
    pkgs.llvm
