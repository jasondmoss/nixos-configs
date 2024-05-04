{ config, lib, pkgs, modulesPath, ... }:
{
    imports = [
        (modulesPath + "/installer/scan/not-detected.nix")
    ];

    boot = {
        kernelPackages = pkgs.linuxPackages_latest;

        kernelModules = [
            "kvm-intel"
            "module_blacklist=i915"
        ];

        kernelParams = [
            "amd_iommu=on"
            "mem_sleep_default=deep"
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

            kernelModules = [ "dm-snapshot" ];

            luks.devices = {
                crypted = {
                    device = "/dev/disk/by-uuid/5e02c30a-d26f-41fb-ba83-b9f2e3b39b5e";
                    preLVM = true;
                };
            };
        };

        blacklistedKernelModules = [ "nouveau" ];

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

        opengl = {
            enable = true;
            driSupport = true;
            driSupport32Bit = true;

            extraPackages = with pkgs; [
                intel-media-driver
                libvdpau-va-gl
                nvidia-vaapi-driver
                vaapiIntel
                vaapiVdpau
                vulkan-validation-layers
            ];
        };

        nvidia = {
            open = false;
            nvidiaPersistenced = true;
            nvidiaSettings = true;
            modesetting.enable = true;

            package = config.boot.kernelPackages.nvidiaPackages.beta;
            # package = config.boot.kernelPackages.nvidiaPackages.vulkan_beta;

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

        pulseaudio.enable = false;
    };

    virtualisation.docker = {
        enable = true;
        enableOnBoot = true;
        enableNvidia = true;
    };

    powerManagement.cpuFreqGovernor = lib.mkDefault "performance";

    environment.sessionVariables = {
        XDG_MENU_PREFIX = "kde-";

        XCURSOR_THEME = "ComixCursors";
        DEFAULT_BROWSER = "/run/current-system/sw/bin/firefox-nightly";

        QT_QPA_PLATFORMTHEME = "qt6ct";

        # # NVIDIA
        # GBM_BACKEND = "nvidia-drm";
        # __GLX_VENDOR_LIBRARY_NAME = "nvidia";
        # LIBVA_DRIVER_NAME = "nvidia";
        # __GL_GSYNC_ALLOWED = "1";

        # WLR_DRM_NO_ATOMIC = "1";
        # WLR_NO_HARDWARE_CURSORS = "1";

        # # JetBrains
        _JAVA_AWT_WM_NONREPARENTING = "1";

        # SDL_VIDEODRIVER = "wayland";

        MOZ_ENABLE_WAYLAND = "1";
        NIXOS_OZONE_WL = "1";

        GST_PLUGIN_SYSTEM_PATH_1_0=lib.makeSearchPathOutput "lib" "lib/gstreamer-1.0" [
            pkgs.gst_all_1.gst-editing-services
            pkgs.gst_all_1.gst-libav
            pkgs.gst_all_1.gst-plugins-bad
            pkgs.gst_all_1.gst-plugins-base
            pkgs.gst_all_1.gst-plugins-good
            pkgs.gst_all_1.gst-plugins-ugly
            pkgs.gst_all_1.gstreamer
        ];
    };
}
