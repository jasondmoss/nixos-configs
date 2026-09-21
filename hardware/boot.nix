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
            "pcie_aspm=off"
        ];

        extraModprobeConfig = "options nvidia " + lib.concatStringsSep " " [
            "NVreg_PreserveVideoMemoryAllocations=1"
            "NVreg_UsePageAttributeTable=1"
        ];

        blacklistedKernelModules = [
            "nouveau"
            "i2c-nvidia_gpu"
        ];

        kernel.sysctl = {
            "fs.inotify.max_user_watches" = 2097152;
            "vm.max_map_count" = 2147483642;
            "kernel.unprivileged_bpf_disabled" = 1;
            "net.core.bpf_jit_harden" = 2;
            "kernel.kptr_restrict" = 2;
            "kernel.yama.ptrace_scope" = 1;

            # Not a router: never emit ICMP redirects; drop RFC 1337 TIME-WAIT
            # assassination; no on-demand line-discipline module autoload.
            "net.ipv4.conf.all.send_redirects" = 0;
            "net.ipv4.conf.default.send_redirects" = 0;
            "net.ipv4.tcp_rfc1337" = 1;
            "dev.tty.ldisc_autoload" = 0;

            # zram swap (./filesystems.nix): no readahead of swap pages
            # (each is decompressed individually anyway).
            "vm.page-cluster" = 0;
        };

        loader = {
            grub.enable = false;

            systemd-boot = {
                enable = true;
                editor = false;
                configurationLimit = 3;
                memtest86.enable = true;
                consoleMode = "auto";
            };

            efi = {
                canTouchEfiVariables = true;
                efiSysMountPoint = "/boot/efi";
            };
        };

        swraid.enable = false;
        tmp.cleanOnBoot = true;
    };

    environment.etc."kernel/install.conf".text = "layout=bls\n";
}

# <> #
