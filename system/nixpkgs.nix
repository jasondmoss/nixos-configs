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

            # opencode 2.2.5 — nixpkgs shipped a stale node_modules outputHash
            # (nixpkgs#582675 carries the correct one). Guarded on the stale hash,
            # so it goes inert once the channel moves on; drop it then.
            (final: prev: {
                opencode = prev.opencode.overrideAttrs (old:
                    prev.lib.optionalAttrs (old.node_modules.outputHash == "sha256-xfOVcw1+waLVNhFDwzOtzxrUSQEogvn88YomydOlhwc=") {
                        node_modules = old.node_modules.overrideAttrs {
                            outputHash = "sha256-prx9dX7kUvs/E3zopkaPk5LXh3xJAy5sZeum/W8L7cA=";
                        };
                    });
            })

            # rar 7.23 is a prebuilt binary; autoPatchelfHook with patchelf 0.19.2
            # leaves rar/unrar segfaulting on every run (same regression as
            # nvidia-smi, nixpkgs#576412). Ark's clirar plugin ignores the crash
            # and reports success, so "Extract and trash archive" trashed RARs
            # unextracted. Pin patchelf 0.15.2 for this build, as nixpkgs does
            # for CUDA redists. Guarded on 0.19.2, so it goes inert once patchelf
            # moves; check that `unrar` still runs then.
            (final: prev: {
                rar = prev.rar.overrideAttrs (old:
                    prev.lib.optionalAttrs (prev.patchelf.version == "0.19.2") {
                        nativeBuildInputs = [
                            (prev.patchelf.overrideAttrs {
                                version = "0.15.2";
                                src = prev.fetchurl {
                                    url = "https://github.com/NixOS/patchelf/releases/download/0.15.2/patchelf-0.15.2.tar.bz2";
                                    hash = "sha256-F3RfVkFZyOIo/EEtplogSLhGxLa0Igt3y/IkFuAvLXw=";
                                };
                            })
                        ] ++ old.nativeBuildInputs;
                    });
            })

            # Disable Vulkan for Chrome — incompatible with
            # --ozone-platform=wayland (NIXOS_OZONE_WL=1).
            # plasmaSupport puts Qt 6 + plasma-integration on the wrapper's
            # LD_LIBRARY_PATH/QT_PLUGIN_PATH; without it the bundled
            # libqt6_shim.so cannot load and "Use QT" silently stays Classic.
            (final: prev: {
                google-chrome = (prev.google-chrome.override {
                    commandLineArgs = "--disable-features=Vulkan";
                    plasmaSupport = true;
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
