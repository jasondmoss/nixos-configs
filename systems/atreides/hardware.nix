{ config, lib, pkgs, ... }: {
    boot = {
        # kernelPackages = pkgs.linuxPackages_latest;
        kernelPackages = pkgs.linuxPackages_xanmod_latest;

        kernelParams = [
            "amd_iommu=on"
            "mem_sleep_default=deep"
        ];

        initrd = {
            availableKernelModules = [
                "nvidia"
                "nvidia_modeset"
                "nvidia_uvm"
                "nvidia_drm"
                "nvme"
                "xhci_pci"
                "ahci"
                "usbhid"
                "usb_storage"
                "sd_mod"
            ];
        };

        kernelModules = [
            "kvm-amd"
        ];

        blacklistedKernelModules = [
            "nouveau"
        ];

        extraModulePackages = [];

        kernel.sysctl = {
            "fs.inotify.max_user_watches" = 2140000000;
        };

        loader = {
            systemd-boot.enable = true;
            grub.enable = false;

            efi = {
                efiSysMountPoint = "/boot/efi";
                canTouchEfiVariables = true;
            };
        };

        swraid.enable = false;
    };

    fileSystems."/" = {
        device = "/dev/disk/by-uuid/f3e63afc-6602-4f46-845d-bd6d5bc6afe3";
        fsType = "ext4";
    };

    fileSystems."/home" = {
        device = "/dev/disk/by-uuid/4d656a69-dc46-46b6-bec3-934e12415711";
        fsType = "btrfs";
        options = [ "compress=lzo" ];
    };

    fileSystems."/home/me/Games" = {
        device = "/dev/disk/by-uuid/2cf8ca9d-43ab-4ef5-99ff-0a909e765c5e";
        fsType = "btrfs";
        options = [ "compress=lzo" ];
    };

    fileSystems."/home/me/Mega" = {
        device = "/dev/disk/by-uuid/ccee2c99-427f-40f1-ad72-af6c81be4379";
        fsType = "ext4";
    };

    fileSystems."/home/me/Music" = {
        device = "/dev/disk/by-uuid/bf9410ed-bf55-4341-97f5-5576f80ce071";
        fsType = "ext4";
    };

    fileSystems."/home/me/Videos/Movies" = {
        device = "/dev/disk/by-uuid/52dfd9d6-7557-45fd-83c6-a6bfff2c0c83";
        fsType = "ext4";
    };

    fileSystems."/home/me/Videos/Television" = {
        device = "/dev/disk/by-uuid/629bf422-618b-44e0-8c92-736d0b9db85d";
        fsType = "ext4";
    };

    fileSystems."/boot/efi" = {
        device = "/dev/disk/by-uuid/3430-092D";
        fsType = "vfat";
    };

    swapDevices = [];

    hardware = {
        cpu.amd = {
            ryzen-smu.enable = true;

            sev = {
                enable = true;
                mode = "0660";
                group = "sev";
                user = "root";
            };

            updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
        };

        nvidia = {
            # For now, only this driver works with kernel 6.11+
            package = config.boot.kernelPackages.nvidiaPackages.stable;
            ###
            open = true;
            nvidiaPersistenced = true;

            powerManagement = {
                enable = true;
                finegrained = false;
            };
        };
    };

    virtualisation = {
        virtualbox.host.enable = true;
    };
}
