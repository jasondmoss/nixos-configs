{ lib, pkgs, modulesPath, ... }: {
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

        nvidia = {
            open = true;
            forceFullCompositionPipeline = true;
            modesetting.enable = true;
            nvidiaPersistenced = true;
            nvidiaSettings = true;
            gsp.enable = true;
            datacenter.enable = false;

            powerManagement = {
                enable = false;
                finegrained = false;
            };

            vaapi = {
                enable = true;
                firefox.enable = true;
            };
        };

        bluetooth = {
            enable = true;

            settings = {
                General = {
                    Experimental = "true";
                };
            };
        };

        keyboard.qmk.enable = true;
    };

    virtualisation = {
        virtualbox.host.enable = true;

        docker = {
            enable = true;
            enableOnBoot = true;
            package = pkgs.docker_25;
        };
    };

    powerManagement.cpuFreqGovernor = lib.mkDefault "performance";
}

# <> #
