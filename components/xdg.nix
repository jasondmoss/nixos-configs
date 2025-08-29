{ pkgs, ... }: {

    xdg.portal = {
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

}
