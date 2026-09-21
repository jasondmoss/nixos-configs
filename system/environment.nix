{ lib, pkgs, ... }: {
    environment = {
        pathsToLink = [
            "/share/applications"
            "/share/icons"
            "/share/pixmaps"
        ];

        sessionVariables = {
            # XDG Base Directory Specification.
            XDG_BIN_HOME    = "$HOME/.local/bin";
            XDG_CACHE_HOME  = "$HOME/.cache";
            XDG_CONFIG_HOME = "$HOME/.config";
            XDG_DATA_HOME   = "$HOME/.local/share";

            # Development.
            Qt6_DIR = "${pkgs.kdePackages.qtbase.dev}/lib/cmake/Qt6";
#            EDITOR = "nvim";

            # Telemetry opt-outs honoured by common dev tooling. None of these
            # change functionality; they only stop usage/crash reporting.
            DO_NOT_TRACK = "1";
            DISABLE_TELEMETRY = "1";                # claude-code (Statsig) + others
            DISABLE_ERROR_REPORTING = "1";          # claude-code (Sentry)
            DOTNET_CLI_TELEMETRY_OPTOUT = "1";
            NEXT_TELEMETRY_DISABLED = "1";
            NUXT_TELEMETRY_DISABLED = "1";
            ASTRO_TELEMETRY_DISABLED = "1";
            GATSBY_TELEMETRY_DISABLED = "1";
            STORYBOOK_DISABLE_TELEMETRY = "1";
            TURBO_TELEMETRY_DISABLED = "1";
            CHECKPOINT_DISABLE = "1";               # prisma

            # Electron/Ozone.
            NIXOS_OZONE_WL = "1";
            ELECTRON_OZONE_PLATFORM_HINT = "auto";

            GST_PLUGIN_SYSTEM_PATH_1_0 =
                lib.makeSearchPathOutput "lib" "lib/gstreamer-1.0" (with pkgs.gst_all_1; [
                    gst-plugins-base
                    gst-plugins-good
                    gst-plugins-bad
                    gst-plugins-ugly
                    gst-libav
                    gstreamer
                ]);
        };
    };
}

# <> #
