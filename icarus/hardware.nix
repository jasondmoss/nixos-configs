{ config, lib, pkgs, modulesPath, ... }:
{
    imports = [
        (modulesPath + "/installer/scan/not-detected.nix")
    ];

    boot = {
        kernelPackages = pkgs.linuxPackages_latest;
        kernelModules = [ "kvm-intel" "module_blacklist=i915" ];
        extraModulePackages = [];

        initrd = {
            availableKernelModules = [ "vmd" "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" ];
            kernelModules = [ "dm-snapshot" ];

            luks.devices = {
                crypted = {
                    device = "/dev/disk/by-uuid/5e02c30a-d26f-41fb-ba83-b9f2e3b39b5e";
                    preLVM = true;
                };
            };
        };

        kernel.sysctl = {
            "fs.inotify.max_user_watches" = 2140000000;
        };

        loader = {
            systemd-boot.enable = true;
            efi.canTouchEfiVariables = true;
        };

        swraid.enable = false;
    };

    fileSystems."/" = {
        device = "/dev/disk/by-uuid/5e7a3096-5275-4bb2-973d-b00b032438a6";
        fsType = "ext4";
    };

    fileSystems."/boot" = {
        device = "/dev/disk/by-uuid/C775-BC84";
        fsType = "vfat";
    };

    swapDevices = [
        { device = "/dev/disk/by-uuid/8a9e0e21-ada8-4830-9836-3f9d678ac477"; }
    ];

    networking = {
        useDHCP = lib.mkDefault true;

         firewall = {
             enable = true;
             allowedTCPPorts = [];
             allowedUDPPorts = [];
         };
    };

    hardware = {
        cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

        nvidia = {
            package = config.boot.kernelPackages.nvidiaPackages.beta;
            open = true;
            nvidiaPersistenced = true;
            nvidiaSettings = true;
            modesetting.enable = true;

            powerManagement = {
                enable = true;
                finegrained = true;
            };

            prime = {
                offload.enable = true;
                intelBusId = "PCI:0:2:0";
                nvidiaBusId = "PCI:1:0:0";
            };
        };

        opengl = {
            enable = true;
            driSupport = true;
            driSupport32Bit = true;

            extraPackages = with pkgs; [
                intel-media-driver
                vaapiIntel
                vaapiVdpau
                libvdpau-va-gl
                nvidia-vaapi-driver
            ];
        };

        pulseaudio.enable = false;
    };

    virtualisation.docker = {
        enable = true;
        enableOnBoot = true;
        enableNvidia = true;
    };

    powerManagement.cpuFreqGovernor = lib.mkDefault "performance";
}
