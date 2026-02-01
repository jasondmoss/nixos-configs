{ lib, pkgs, modulesPath, ... }: {
    imports = [
        <nixos-hardware/common/gpu/nvidia/turing>
        (modulesPath + "/installer/scan/not-detected.nix")
    ];

    hardware = {
        graphics = {
            enable = true;
            enable32Bit = true;
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
                enable = true;
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

    powerManagement.cpuFreqGovernor = lib.mkDefault "performance";
}

# <> #
