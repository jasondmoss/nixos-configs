{ pkgs, fetchpatch2, ... }: {
    nixpkgs = {
        hostPlatform = {
            #gcc.arch = "znver2";
            #gcc.tune = "znver2";
            system = "x86_64-linux";
        };

        buildPlatform = {
            #gcc.arch = "znver2";
            #gcc.tune = "znver2";
            system = "x86_64-linux";
        };

        config = {
            allowBroken = false;
            # Global: every unfree package is permitted. (An
            # allowUnfreePredicate is never consulted while this is true, so
            # none is kept here.)
            allowUnfree = true;

            packageOverrides = pkgs: {
                steam = pkgs.steam.override {
                    extraPkgs = pkgs: with pkgs; [
                        libgdiplus
                    ];
                };
            };
        };

        overlays = [
            # Firefox Nightly.
            (import ../overlays/nixpkgs-mozilla/firefox-overlay.nix)

            # PhpStorm.
            (import ./packages/jetbrains)
            (final: prev: {
                phpstorm = prev.phpstorm.overrideAttrs (old: {
                    buildInputs = old.buildInputs ++ [
                        pkgs.nss
                        pkgs.nspr
                        pkgs.libxkbcommon
                    ];
                });
            })

            (import ../overlays/default.nix)

            # Disable Vulkan for Chrome — incompatible with
            # --ozone-platform=wayland (NIXOS_OZONE_WL=1).
            (final: prev: {
                google-chrome = prev.google-chrome.override {
                    commandLineArgs = "--disable-features=Vulkan";
                };
            })
        ];
    };
}

# <> #
