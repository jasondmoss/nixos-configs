{
    system.stateVersion = "24.05";

    imports = [
        ../../shared/hardware.nix
        ./hardware.nix

        ../../shared/configuration.nix
        ./configuration.nix

        ../../shared/packages.nix
        ./packages.nix
    ];

    time.timeZone = "America/Toronto";

    networking.hostName = "icarus";
}
