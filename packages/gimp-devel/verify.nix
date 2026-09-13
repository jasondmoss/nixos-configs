## Post-refresh build check for nxmanifest — see packages/krema/verify.nix.
##
## gimp-devel is only reachable through the overlay in ../gimp, which also
## carries the babl/gegl pins from this package's manifest. The two plugins
## are built too: they link against gimp's libraries and land in
## environment.systemPackages, so a bump that breaks them breaks the rebuild
## just as surely as one that breaks gimp itself.
let
    base = import <nixpkgs> { config.allowUnfree = true; };
    gimpModule = import ../gimp { pkgs = base; lib = base.lib; };
    pkgs = import <nixpkgs> {
        config.allowUnfree = true;
        overlays = gimpModule.nixpkgs.overlays;
    };
in [
    pkgs.gimp-devel
    pkgs.customGimp3Plugins.gmic
    pkgs.customGimp3Plugins.lightning
]

# <> #
