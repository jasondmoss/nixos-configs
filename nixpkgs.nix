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
                "steam"
                "steam-run"
                "steam-original"
                "steam-unwrapped"
                "vulkan-headers"
                "vulkan-loader"
                "vulkan-tool"
                "vulkan-validation-layers"
            ];

            permittedInsecurePackages = [
                "openssl-1.1.1w"
            ];
        };

        overlays = [
            # Firefox Nightly.
            (import ../overlays/nixpkgs-mozilla/firefox-overlay.nix)

            # PhpStorm.
            (import ./packages/jetbrains)
            (final: prev: {
                phpstorm = prev.phpstorm.overrideAttrs (old: {
                    buildInputs = old.buildInputs ++ [
                        pkgs.libGL
                        pkgs.xorg.libX11
                        pkgs.fontconfig
                    ];
                });
            })

            # libQuotient.
            (final: prev: {
                libquotient = prev.libquotient.overrideAttrs (old: {
                    patches = old.patches ++ [
                        (fetchpatch2 {
                            url = "https://github.com/quotient-im/libQuotient/commit/ea83157eed37ff97ab275a5d14c971f0a5a70595.patch";
                        })
                    ];
                });
            })

            (import ../overlays/default.nix)
        ];
    };
}

# <> #
