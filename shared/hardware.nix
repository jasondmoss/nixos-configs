{ lib, pkgs, modulesPath, ... }: {
    imports = [
        (modulesPath + "/installer/scan/not-detected.nix")
    ];

    hardware = {
        graphics = {
            enable = true;
            enable32Bit = true;

            extraPackages = with pkgs; [
                intel-media-driver
            ];
        };

        nvidia = {
            forceFullCompositionPipeline = true;
            nvidiaSettings = true;
            gsp.enable = true;
        };

        nvidia-container-toolkit.enable = true;

        pulseaudio = {
            enable = false;

            zeroconf = {
                publish.enable = false;
                discovery.enable = false;
            };
        };
    };

    virtualisation.docker = {
        enable = true;
        enableOnBoot = true;
    };

    powerManagement.cpuFreqGovernor = lib.mkDefault "performance";
}
