{ config, pkgs, lib, ... }:

{
    # WARNING: This overlay triggers a world rebuild (compiling all packages that depend on GMP).
    nixpkgs.overlays = [
        (final: prev: {
            gmp = prev.gmp.overrideAttrs (old: {
                # This forces the generation of a debug output and ensures
                # the .note.gnu.build-id section is preserved in the binary.
                separateDebugInfo = true;
            });
        })
    ];

    environment = {
        # Links debug outputs of systemPackages to /run/current-system/sw/lib/debug
        enableDebugInfo = true;

        systemPackages = with pkgs; [
            # Tools
            gdb
            elfutils

            # Debug Symbols
            # We explicitly include gmp here so enableDebugInfo links its new debug output.
            gmp

            # Common stack trace culprits
            glibc.debug
            qt6.qtbase.debug
        ];
    };

    environment.variables = {
        NIX_DEBUG_INFO_DIRS = "/run/current-system/sw/lib/debug";
    };
}
