{ pkgs, ... }: {
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
}

# <> #
