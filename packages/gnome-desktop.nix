{ pkgs, ... }: {

    programs = {
        dconf.enable = true;
    };

    services = {
        xserver.desktopManager.gnome.enable = true;
    };

    environment = {
        gnome.excludePackages = (with pkgs; [
            gnome-tour
        #]) ++ (with pkgs.gnome; [
        #]) ++ (with pkgs.gnomeExtensions; [
        ]);

        systemPackages = (with pkgs; [

            adwaita-icon-theme
            #gnome-boxes
            gnome-browser-connector
            gnome-control-center
            gnome-shell
            gnome-tweaks
            nautilus
            nautilus-open-any-terminal

        ]);
    };
}
