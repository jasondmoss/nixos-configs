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

            (final: prev: {
                conky = prev.conky.overrideAttrs (old: rec {
                    version = "1.24.2";
                    src = final.fetchFromGitHub {
                        owner = "brndnmtthws";
                        repo = "conky";
                        tag = "v${version}";
                        hash = "sha256-fnH87Ts28t2FIKQkrXjlOFG1NIDPq0JqfDR9aIfog6I=";
                    };
                    # 1.24.x makes XInput2 mandatory under X11.
                    buildInputs = old.buildInputs ++ [ final.libxi ];
                });
            })

            # Disable Vulkan for Chrome — incompatible with
            # --ozone-platform=wayland (NIXOS_OZONE_WL=1).
            (final: prev: {
                google-chrome = prev.google-chrome.override {
                    commandLineArgs = "--disable-features=Vulkan";
                };
            })

            # TEMPORARY (remove once nixos-unstable advances past PR #552075):
            # GitHub regenerated the nanoemoji v0.16.0 tarball, changing its
            # hash. The fix is already on nixpkgs master but has not reached the
            # nixos-unstable channel branch yet (channel lag). This overrides the
            # src hash to master's corrected value so the font toolchain
            # (nanoemoji -> gftools -> jetbrains-mono) builds now. Verify with
            # `nxin 552075`; once contained, delete this overlay + update channel.
            (final: prev: {
                pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
                    (pyfinal: pyprev: {
                        nanoemoji = pyprev.nanoemoji.overridePythonAttrs (o: {
                            src = o.src.overrideAttrs (_: {
                                outputHash = "sha256-FysyKC01XBnRiur5RR9fcsTxQqE8x0JJHSoe3q6JtKc=";
                            });
                        });
                    })
                ];
            })
        ];
    };
}

# <> #
