{ pkgs, ... }: {
    programs = {
        dconf.enable = true;
    };

    services = {
        xserver.desktopManager.gnome.enable = true;
    };

    environment = {
        gnome.excludePackages = (with pkgs; [
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
            #gnome-boxes
            #gnome-browser-connector
            #gnome-control-center
            #gnome-shell
            #gnome-tweaks
            gtk4
            nautilus
            #nautilus-open-any-terminal
        ]);
    };
}
