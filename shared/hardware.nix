{ lib, pkgs, modulesPath, inputs, ... }: {
    imports = [
        <nixos-hardware/common/gpu/nvidia/turing>
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

        #nvidia = {
        #    forceFullCompositionPipeline = true;
        #    nvidiaSettings = true;
        #    datacenter.enable = false;
        #    gsp.enable = true;
        #};

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
