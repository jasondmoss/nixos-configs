{ pkgs, ... }: {
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
            (import ../../overlays/nixpkgs-mozilla/firefox-overlay.nix)

            # PhpStorm.
            (import ../packages/jetbrains)
            (final: prev: {
                phpstorm = prev.phpstorm.overrideAttrs (old: {
                    buildInputs = old.buildInputs ++ [
                        pkgs.nss
                        pkgs.nspr
                        pkgs.libxkbcommon
                    ];
                });
            })

            (import ../../overlays/default.nix)

            # Disable Vulkan for Chrome — incompatible with
            # --ozone-platform=wayland (NIXOS_OZONE_WL=1).
            #
            # Chrome reads "external extension" descriptors (<id>.json →
            # local CRX) from <install dir>/extensions/, i.e.
            # $out/share/google/chrome/extensions here; Linux Chrome installs
            # them enabled, without a prompt (verified 153, headless). The
            # directory is a symlink to /etc/opt/chrome/extensions, filled by
            # environment.etc in ../desktop/browsers.nix from the unclutter package, so
            # an extension update never rebuilds the 430 MB Chrome closure.
            # (--load-extension is ignored by branded Chrome since 137, and
            # ExtensionInstallForcelist needs an http(s) update manifest.)
            (final: prev: {
                google-chrome = (prev.google-chrome.override {
                    commandLineArgs = "--disable-features=Vulkan";
                }).overrideAttrs (old: {
                    postInstall = (old.postInstall or "") + ''
                        ln -s /etc/opt/chrome/extensions "$out/share/google/chrome/extensions"
                    '';
                });
            })
        ];
    };
}

# <> #
