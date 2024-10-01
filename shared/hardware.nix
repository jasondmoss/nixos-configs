{ config, lib, pkgs, modulesPath, ... }: {
    imports = [
        (modulesPath + "/installer/scan/not-detected.nix")
    ];

    hardware = {
        graphics = {
            enable = true;
            enable32Bit = true;

            extraPackages = with pkgs; [
                intel-media-driver
                libvdpau-va-gl
                # nvidia-vaapi-driver
                # vaapiVdpau
            ];
        };

        nvidia = {
            forceFullCompositionPipeline = true;
            modesetting.enable = true;
            nvidiaPersistenced = true;
            nvidiaSettings = true;
            # open = false;

            powerManagement = {
                enable = false;
                finegrained = false;
            };

            # package = config.boot.kernelPackages.nvidiaPackages.stable;
            # package = config.boot.kernelPackages.nvidiaPackages.latest;
            # package = config.boot.kernelPackages.nvidiaPackages.beta;
            # package = config.boot.kernelPackages.nvidiaPackages.vulkan_beta;
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
