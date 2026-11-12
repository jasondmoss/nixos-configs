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

            # PhpStorm — the whole override lives in the package (its nss/nspr/
            # libxkbcommon fix too), so packages/jetbrains/verify.nix builds the
            # exact derivation this rebuild uses.
            (import ../packages/jetbrains)

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

            # Rust system libs (2026-11-09) — cargoSetupHook now forces the
            # system aws-lc, openssl, zlib, sqlite, zstd, libgit2, … into every
            # Rust build (26.11 release notes), and packages nixpkgs has not
            # adapted yet panic in their -sys build scripts (tectonic: aws-lc;
            # goose-cli, primp: aws-lc + zstd; chromadb: sqlite).
            # dontCargoUseSystemLibs is the documented opt-out and restores the
            # vendored build Hydra did before. Not self-retiring: drop an entry
            # once its package shows up as "will be fetched" in
            # `nix-build '<nixpkgs/nixos>' -A config.system.build.toplevel --dry-run`
            # without it.
            (final: prev: let
                vendored = _: { dontCargoUseSystemLibs = true; };
            in {
                tectonic-unwrapped = prev.tectonic-unwrapped.overrideAttrs vendored;
                goose-cli = prev.goose-cli.overrideAttrs vendored;

                pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
                    (pyfinal: pyprev: {
                        primp = pyprev.primp.overridePythonAttrs vendored;       # → ddgs → open-webui
                        chromadb = pyprev.chromadb.overridePythonAttrs vendored; # → open-webui
                    })
                ];
            })

            # Python test-suite breakage (2026-11-09); each entry drops only the
            # failing tests, drop the entry once nixpkgs builds the package.
            # speechrecognition 3.17.0 — openai 3.14 sends through
            # the httpx2 fork, which respx (mocks httpx only) cannot intercept,
            # so test_openai.py hits the real API and fails on the sandbox's
            # missing DNS. Chain: speechrecognition → markitdown →
            # markitdown-mcp → ai-home-mcp. Drop once nixpkgs skips it itself.
            (final: prev: {
                pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
                    (pyfinal: pyprev: {
                        speechrecognition = pyprev.speechrecognition.overridePythonAttrs (old: {
                            disabledTestPaths = (old.disabledTestPaths or [ ])
                                ++ [ "tests/recognizers/whisper_api/test_openai.py" ];
                        });

                        # geopandas 1.1.4 → pdfplumber/markitdown → markitdown-mcp.
                        # nixpkgs' shapely 2.2.0 reports __version__ '0+unknown',
                        # so pyogrio's `Version(shapely.__version__) < 2.0` check
                        # rejects the mask= tests; the geoarrow point round-trips
                        # trip pyarrow 24 (ArrowInvalid column length). Test-only:
                        # fixing shapely itself would rebuild scikit-learn,
                        # torchaudio, langchain, … locally.
                        geopandas = pyprev.geopandas.overridePythonAttrs (old: {
                            disabledTests = (old.disabledTests or [ ]) ++ [
                                "test_read_file_mask"
                                "test_read_file_crs_warning_messages"
                                "test_read_file_multi_layer_with_layer_arg_no_warning"
                                "test_geoarrow_roundtrip"
                                "test_geoarrow_missing"
                            ];
                        });
                    })
                ];
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
