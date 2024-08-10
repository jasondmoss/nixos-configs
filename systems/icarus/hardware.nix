{ config, lib, pkgs, modulesPath, ... }:
{
    boot = {
        kernelPackages = pkgs.linuxPackages_latest;

        kernelModules = [
            "kvm-intel"
        ];

        kernelParams = [
            "amd_iommu=on"
            #"i915.modeset=0"
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

        blacklistedKernelModules = [
            # "i915"
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
        cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

        nvidia = {
            forceFullCompositionPipeline = true;
            modesetting.enable = true;
            nvidiaPersistenced = true;
            nvidiaSettings = true;
            open = false;

            powerManagement = {
                enable = false;
                finegrained = false;
            };

            prime = {
                offload.enable = true;
                intelBusId = "PCI:0:2:0";
                nvidiaBusId = "PCI:1:0:0";
            };

            # package = config.boot.kernelPackages.nvidiaPackages.latest;
            # package = config.boot.kernelPackages.nvidiaPackages.beta;
            package = config.boot.kernelPackages.nvidiaPackages.vulkan_beta;
        };
    };

    services = {
        xserver = {
           screenSection = ''
Option "metamodes" "nvidia-auto-select +0+0 {ForceFullCompositionPipeline=On}"
Option "AllowIndirectGLXProtocol" "off"
Option "TripleBuffer" "on"
           '';
        };
    };

    environment.sessionVariables = {
        XDG_MENU_PREFIX = "kde-";

        XCURSOR_THEME = "ComixCursors";
        DEFAULT_BROWSER = "/run/current-system/sw/bin/firefox-nightly";

        QT_QPA_PLATFORMTHEME = "qt6ct";
        QT_SCALE_FACTOR = "1";
        QT_AUTO_SCREEN_SCALE_FACTOR = "1";
        PLASMA_USE_QT_SCALING = "1";
        KWIN_TRIPLE_BUFFER = "1";

        # NVIDIA
        GBM_BACKEND = "nvidia-drm";
        __GLX_VENDOR_LIBRARY_NAME = "nvidia";
        LIBVA_DRIVER_NAME = "nvidia";
        __GL_GSYNC_ALLOWED = "1";

        WLR_DRM_NO_ATOMIC = "1";
        WLR_NO_HARDWARE_CURSORS = "1";

        # JetBrains
        _JAVA_AWT_WM_NONREPARENTING = "1";

        SDL_VIDEODRIVER = "wayland";

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
