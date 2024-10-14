{
    system.stateVersion = "24.05";

    imports = [
        ./hardware.nix
        ../../shared/hardware.nix

        ../../shared/configuration.nix
        ./configuration.nix

        ../../shared/packages.nix
        ./packages.nix
    ];

    time.timeZone = "America/Toronto";

    networking.hostName = "atreides";
}
