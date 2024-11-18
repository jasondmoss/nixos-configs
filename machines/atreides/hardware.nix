{ config, lib, pkgs, ... }: {

    boot = {
        kernelPackages = pkgs.linuxPackages_xanmod_latest;
        # kernelPackages = pkgs.linuxPackages_latest;
        #kernelPackages = pkgs.linuxPackagesFor (pkgs.linux_6_10.override {
        #    argsOverride = rec {
        #        src = pkgs.fetchurl {
        #            url = "mirror://kernel/linux/kernel/v6.x/linux-${version}.tar.xz";
        #            sha256 = "sha256-5ofnNbXrnvttZ7QkM8k/yRGBBqmVUU8GJlKHO16Am80=";
        #        };
        #        version = "6.10.10";
        #        modDirVersion = "6.10.10";
        #    };
        #});

        kernelParams = [
            "amd_iommu=on"
            "mem_sleep_default=deep"
            "nvidia-drm.fbdev=1"
            "nvidia-drm.modeset=1"
        ];

        extraModprobeConfig = "options nvidia " + lib.concatStringsSep " " [
            "NVreg_UsePageAttributeTable=1"
            "NVreg_EnablePCIeGen3=1"
            "NVreg_PreserveVideoMemoryAllocations=1"
            "NVreg_RegistryDwords=RMUseSwI2c=0x01;RMI2cSpeed=100"
        ];

        initrd = {
            availableKernelModules = [
                "nvme"
                "xhci_pci"
                "ahci"
                "usbhid"
                "usb_storage"
                "sd_mod"
            ];

            kernelModules = [
                "nvidia"
                "nvidia_modeset"
                "nvidia_uvm"
                "nvidia_drm"
                "i2c-nvidia_gpu"
                "kvm-amd"
            ];
        };

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

            #package = config.boot.kernelPackages.nvidiaPackages.beta;

            # Beta branch.
            #package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
            #    version = "565.57.01";
            #    sha256_64bit = "sha256-buvpTlheOF6IBPWnQVLfQUiHv4GcwhvZW3Ks0PsYLHo=";
            #    openSha256 = "sha256-hdszsACWNqkCh8G4VBNitDT85gk9gJe1BlQ8LdrYIkg=";
            #    settingsSha256 = "sha256-hdszsACWNqkCh8G4VBNitDT85gk9gJe1BlQ8LdrYIkg=";
            #    persistencedSha256 = "sha256-H7uEe34LdmUFcMcS6bz7sbpYhg9zPCb/5AmZZFTx1QA=";
            #};

            # New feature branch.
            #package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
            #    version = "560.35.03";
            #    sha256_64bit = "sha256-8pMskvrdQ8WyNBvkU/xPc/CtcYXCa7ekP73oGuKfH+M=";
            #    openSha256 = "sha256-/32Zf0dKrofTmPZ3Ratw4vDM7B+OgpC4p7s+RHUjCrg=";
            #    settingsSha256 = "sha256-kQsvDgnxis9ANFmwIwB7HX5MkIAcpEEAHc8IBOLdXvk=";
            #    persistencedSha256 = "sha256-E2J2wYYyRu7Kc3MMZz/8ZIemcZg68rkzvqEwFAL3fFs=";
            #};
        };
    };

    virtualisation = {
        virtualbox.host.enable = true;
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

}
