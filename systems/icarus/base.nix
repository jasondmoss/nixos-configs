{ config, options, pkgs, ... }:
{
    system.stateVersion = "24.05";

    imports = [
        ./hardware.nix
        ../../shared/hardware.nix

        ../../shared/configuration.nix

        ../../shared/applications.nix
        # ./applications.nix

        # JetBrains PHPStorm Beta
        custom/jetbrains/default.nix
    ];

    time.timeZone = "America/Toronto";

    networking.hostName = "icarus";

    services.xserver.dpi = 96;
}
