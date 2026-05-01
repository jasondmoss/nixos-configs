{ lib, pkgs, modulesPath, ... }: {
    imports = [
        (modulesPath + "/installer/scan/not-detected.nix")
    ];

    boot = {
        kernelPackages = pkgs.linuxPackages_xanmod_latest;

        initrd = {
            systemd.enable = true;

            kernelModules = [
                "nvidia"
                "nvidia_drm"
                "nvidia_modeset"
                "nvidia_uvm"
            ];

            availableKernelModules = [
                "ahci"
                "nvme"
                "sd_mod"
                "usb_storage"
                "usbhid"
                "xhci_pci"
            ];
        };

        kernelModules = [
            "kvm-amd"
            "k10temp"
        ];

        kernelParams = [
            "amd_iommu=on"
            "amd_pstate=active"
            "nvidia-drm.fbdev=1"
            "nvidia-drm.modeset=1"
        ];

        extraModprobeConfig = "options nvidia " + lib.concatStringsSep " " [
            "NVreg_EnablePCIeGen3=1"
            "NVreg_PreserveVideoMemoryAllocations=1"
            "NVreg_RegistryDwords=RMUseSwI2c=0x01;RMI2cSpeed=100"
            "NVreg_UsePageAttributeTable=1"
        ];

        blacklistedKernelModules = [
            "nouveau"
            "i2c-nvidia_gpu"
        ];

        kernel.sysctl = {
            "fs.inotify.max_user_watches" = 2140000000;
            "kernel.unprivileged_bpf_disabled" = 1;
            "net.core.bpf_jit_harden" = 2;
            "kernel.kptr_restrict" = 2;
            "kernel.yama.ptrace_scope" = 1;
        };

        loader = {
            grub.enable = false;

            systemd-boot = {
                enable = true;
                memtest86.enable = true;
                consoleMode = "auto";
            };

            efi = {
                canTouchEfiVariables = true;
                efiSysMountPoint = "/boot/efi";
            };
        };

        swraid.enable = false;
    };

    #
    # Filesystems.
    #

    # [nvme0n1p2]
    fileSystems."/" = {
        device = "/dev/disk/by-uuid/f3e63afc-6602-4f46-845d-bd6d5bc6afe3";
        fsType = "ext4";
    };

    # [nvme1n1p1]
    fileSystems."/home" = {
        device = "/dev/disk/by-uuid/4d656a69-dc46-46b6-bec3-934e12415711";
        fsType = "btrfs";
        options = [ "compress=zstd:1" ];
    };

    # [sdb2]
    fileSystems."/home/me/Mega" = {
        device = "/dev/disk/by-uuid/ccee2c99-427f-40f1-ad72-af6c81be4379";
        fsType = "ext4";
    };

    # [sdc1]
    fileSystems."/home/me/Music" = {
        device = "/dev/disk/by-uuid/bf9410ed-bf55-4341-97f5-5576f80ce071";
        fsType = "ext4";
    };

    # [sdb1]
    fileSystems."/home/me/Repository" = {
        device = "/dev/disk/by-uuid/2cf8ca9d-43ab-4ef5-99ff-0a909e765c5e";
        fsType = "btrfs";
        options = [ "compress=zstd:1" ];
    };

    # [sda1]
    fileSystems."/home/me/Videos/Movies" = {
        device = "/dev/disk/by-uuid/52dfd9d6-7557-45fd-83c6-a6bfff2c0c83";
        fsType = "ext4";
    };

    # [sdd]
     fileSystems."/home/me/Videos/Television" = {
         device = "/dev/disk/by-uuid/a7007b9d-f315-4dec-83cd-ef883729e3c0";
         fsType = "ext4";
     };

    fileSystems."/boot/efi" = {
        device = "/dev/disk/by-uuid/3430-092D";
        fsType = "vfat";
    };

    swapDevices = [{
        device = "/swapfile";
        size = 16 * 1024;  # 16GB
    }];
}

# <> #
