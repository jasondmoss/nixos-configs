{ pkgs, ... }: {

    programs = {
        dconf.enable = true;
    };

    services.desktopManager.gnome.enable = true;

    environment = {
        gnome.excludePackages = (with pkgs; [
            decibels
            geary
            gnome-calculator
            gnome-calendar
            gnome-console
            gnome-contacts
            gnome-maps
            gnome-music
            gnome-tour
            gnome-weather
        ]);

        systemPackages = (with pkgs; [
            adwaita-icon-theme
            gcolor3
            glib-networking
#            gnome-boxes
#            gnome-browser-connector
#            gnome-control-center
#            gnome-shell
            gnome-tweaks
            gtk4
            libadwaita
            morewaita-icon-theme
            nautilus
#            nautilus-open-any-terminal
        ]);
    };

}
