{ pkgs, ... }: {
    # Setup.
    nixpkgs = {
        config = {
            allowBroken = true;
            allowUnfree = true;

            packageOverrides = pkgs: {
                steam = pkgs.steam.override {
                    extraPkgs = pkgs: with pkgs; [
                        libgdiplus
                    ];
                };
            };

            allowUnfreePredicate = pkg: builtins.elem (pkgs.lib.getName pkg) [
                "nvidia-x11"
                "nvidia-persistenced"
                "nvidia-settings"
                "nvidia-vaapi-driver"
                "vulkan-headers"
                "vulkan-loader"
                "vulkan-tool"
                "vulkan-validation-layers"
            ];

            permittedInsecurePackages = [
                "olm-3.2.16"
                "openssl-1.1.1w"
                "qtwebengine-5.15.19"
            ];
        };

        overlays = [
            # Conky
#            (import ../packages/conky)

            # Firefox Nightly
            (import ../../overlays/nixpkgs-mozilla/firefox-overlay.nix)


            # PhpStorm
            (import ../packages/jetbrains)
            (final: prev: {
                phpstorm = prev.phpstorm.overrideAttrs (old: {
                    buildInputs = old.buildInputs ++ [
                        pkgs.libGL
                        pkgs.xorg.libX11
                        pkgs.fontconfig
                    ];
                });
            })
        ];
    };
}

# <> #
