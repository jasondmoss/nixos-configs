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

        nvidia = {
            open = true;
            forceFullCompositionPipeline = true;
            modesetting.enable = true;
            nvidiaPersistenced = true;
            nvidiaSettings = true;
            datacenter.enable = false;
            gsp.enable = true;

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

        #pulseaudio = {
        #    enable = false;
        #
        #    zeroconf = {
        #        publish.enable = false;
        #        discovery.enable = false;
        #    };
        #};

        keyboard.qmk.enable = true;
    };

    virtualisation.docker = {
        enable = true;
        enableOnBoot = true;
    };

    powerManagement.cpuFreqGovernor = lib.mkDefault "performance";
}
