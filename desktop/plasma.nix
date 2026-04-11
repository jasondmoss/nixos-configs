{ pkgs, ... }: {
    qt.enable = true;
    qt.platformTheme = "kde";

    services = {
        displayManager = {
            enable = true;

            ly = {
                enable = true;
                x11Support = false;

                settings = {
                    clear_password = true;
                    clock = "%c";
                    #animation = "matrix";
                    #animation_timeout_sec = "20";
                    animation = "none";
                    input_len = "64";
                    waylandsessions = "${pkgs.kdePackages.plasma-workspace}/share/wayland-sessions";
                };
            };

            defaultSession = "plasma";
        };

        desktopManager.plasma6 = {
           enable = true;
           enableQt5Integration = false;
        };
    };

    # XDG portals and MIME defaults.
    xdg = {
        mime.defaultApplications = {
            "text/html" = "firefox-nightly.desktop";
            "x-scheme-handler/http" = "firefox-nightly.desktop";
            "x-scheme-handler/https" = "firefox-nightly.desktop";
            "x-scheme-handler/about" = "firefox-nightly.desktop";
            "x-scheme-handler/unknown" = "firefox-nightly.desktop";
        };

        portal = {
            enable = true;
            xdgOpenUsePortal = true;
            config = {
                kde.default = [ "kde" "gtk" "gnome" ];
                kde."org.freedesktop.portal.FileChooser" = [ "kde" ];
                kde."org.freedesktop.portal.OpenURI" = [ "kde" ];
            };
            extraPortals = with pkgs; [
                xdg-desktop-portal
                xdg-desktop-portal-termfilechooser
                kdePackages.xdg-desktop-portal-kde
            ];
        };
    };

    # Plasma 6 & Qt session variables.
    environment.sessionVariables = {
        KDE_SESSION_VERSION = "6";
        QT_QPA_PLATFORM = "wayland;xcb";
        # Transition from 'software' to 'rhi' (Render Hardware Interface).
        QT_QUICK_BACKEND = "rhi";
        PLASMA_USE_QT_SCENE_GRAPH_BACKEND = "opengl";
    };
}

# <> #
