{ config, lib, pkgs, modulesPath, ... }:
{
    boot = {
        kernelParams = [
            # "amd_iommu=on"
            #"i915.modeset=0"
            "mem_sleep_default=deep"
            "nvidia_drm.fbdev=1"
            "nvidia-drm.modeset=1"
        ];

        initrd = {
            availableKernelModules = [
                "vmd"
                "xhci_pci"
                "ahci"
                "nvme"
                "usbhid"
                "usb_storage"
                "sd_mod"
            ];

            kernelModules = [
                "dm-snapshot"
            ];

            luks.devices = {
                crypted = {
                    device = "/dev/disk/by-uuid/5e02c30a-d26f-41fb-ba83-b9f2e3b39b5e";
                    preLVM = true;
                };
            };
        };

        kernelModules = [
            "kvm-intel"
        ];

        extraModprobeConfig = "options nvidia " + lib.concatStringsSep " " [
            "NVreg_UsePageAttributeTable=1"
            "NVreg_EnablePCIeGen3=1"
            "NVreg_PreserveVideoMemoryAllocations=1"
            #"NVreg_RegistryDwords=RMUseSwI2c=0x01;RMI2cSpeed=100"
        ];

        kernelPackages = pkgs.linuxPackages_latest;

        blacklistedKernelModules = [
            "nouveau"
        ];

        extraModulePackages = [];

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
        {
            device = "/dev/disk/by-uuid/8a9e0e21-ada8-4830-9836-3f9d678ac477";
        }
    ];

    hardware = {
        cpu.intel = {
            updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
        };

        nvidia.prime = {
            offload.enable = true;
            intelBusId = "PCI:0:2:0";
            nvidiaBusId = "PCI:1:0:0";
        };
    };

    services.xserver.dpi = 96;
}
