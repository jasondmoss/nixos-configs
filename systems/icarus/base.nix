{ config, options, pkgs, ... }:
{
    system.stateVersion = "24.05";

    imports = [
        ./hardware.nix
        ../../shared/hardware.nix

        ../../shared/configuration.nix

        ../../shared/applications.nix
        ./applications.nix
    ];

    time.timeZone = "America/Toronto";

    networking.hostName = "icarus";

    services = {
        printing.enable = false;

        avahi = {
            enable = false;
            # nssmdns4 = true;
            # openFirewall = true;
        };

        xserver.dpi = 96;
    };
}
