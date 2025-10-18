################################################################################
 ##                                                                          ##
 ##                             ·: ICARUS :·                                 ##
 ##                                                                          ##
################################################################################

{ config, lib, pkgs, ... }: {
    nix.settings.system-features = [
        "benchmark"
        "big-parallel"
        "kvm"
        "nixos-test"
        "gccarch-alderlake"
    ];

    system.stateVersion = "25.05";
    time.timeZone = "America/Toronto";
    networking.hostName = "icarus";

    boot = {
        kernelPackages = pkgs.linuxPackages_xanmod_latest;
#        kernelPackages = pkgs.linuxPackages_latest;

        initrd = {
            systemd.enable = true;

            kernelModules = [
                "dm-snapshot"
                "i2c-nvidia_gpu"
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
                "vmd"
                "xhci_pci"
            ];

            luks.devices.crypted = {
                device = "/dev/disk/by-uuid/5e02c30a-d26f-41fb-ba83-b9f2e3b39b5e";
                preLVM = true;
            };
        };

        kernelModules = [
            "kvm-intel"
        ];

        kernelParams = [
            "intel_iommu=on"
            "mem_sleep_default=deep"
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
        ];

        kernel.sysctl = {
            "fs.inotify.max_user_watches" = 2140000000;
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
            };
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

    swapDevices = [{
        device ="/swapfile";
        size = 16 * 1024;  # 16GB
    }];

    hardware = {
        cpu.intel = {
            sgx.provision = {
                enable = true;
            };

            updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
        };

        nvidia = {
            package = config.boot.kernelPackages.nvidiaPackages.beta;

            prime = {
                offload = {
                    enable = false;
                    enableOffloadCmd = false;
                };

                sync.enable = true;
                nvidiaBusId = "PCI:1:0:0";
                intelBusId = "PCI:0:2:0";
            };
        };
    };

    console.font = "Lat2-Terminus16";

    services = {
        power-profiles-daemon.enable = false;
        printing.enable = true;
        xserver.dpi = 96;

        avahi = {
            enable = true;
            nssmdns4 = true;
            openFirewall = true;
        };

        tlp = {
            enable = true;
            settings = {
                CPU_SCALING_GOVERNOR_ON_AC = "performance";
                CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

                CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
                CPU_ENERGY_PERF_POLICY_ON_AC = "performance";

                CPU_MIN_PERF_ON_AC = 0;
                CPU_MAX_PERF_ON_AC = 100;
                CPU_MIN_PERF_ON_BAT = 0;
                CPU_MAX_PERF_ON_BAT = 20;

                START_CHARGE_THRESH_BAT0 = 40;
                STOP_CHARGE_THRESH_BAT0 = 80;
            };
        };

        printing = {
            browsing = true;
            cups-pdf.enable = true;
            startWhenNeeded = true;
        };
    };

    nixpkgs = {
        hostPlatform = {
            #gcc.arch = "alderlake";
            #gcc.tune = "alderlake";
            system = "x86_64-linux";
        };

        buildPlatform = {
            #gcc.arch = "alderlake";
            #gcc.tune = "alderlake";
            system = "x86_64-linux";
        };
    };

    virtualisation = {
        virtualbox.host.enable = true;
    };

    environment = {
        systemPackages = (with pkgs; [
            tor-browser-bundle-bin
        ]);
    };

    imports = [
        ../common.nix

        # System-specific packages.
#        ../packages/ollama
    ];
}

# <> #
