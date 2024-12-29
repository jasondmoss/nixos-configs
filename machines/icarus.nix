################################################################################
##                              ·: ICARUS :·                                  ##
################################################################################

{ config, lib, pkgs, ... }: {
    boot = {
        loader = {
            systemd-boot.enable = true;
            efi.canTouchEfiVariables = true;
        };

        kernelModules = [
            "kvm-intel"
        ];

        initrd = {
            kernelModules = [
                "dm-snapshot"
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

            luks.devices = {
                crypted = {
                    device = "/dev/disk/by-uuid/5e02c30a-d26f-41fb-ba83-b9f2e3b39b5e";
                    preLVM = true;
                };
            };
        };

        kernelParams = [
            "intel_iommu=on"
            "mem_sleep_default=deep"
            "nvidia_drm.fbdev=1"
            "nvidia_drm.modeset=1"
        ];

        extraModprobeConfig = "options nvidia " + lib.concatStringsSep " " [
            "NVreg_UsePageAttributeTable=1"
            "NVreg_EnablePCIeGen3=1"
            "NVreg_PreserveVideoMemoryAllocations=1"
            "NVreg_RegistryDwords=RMUseSwI2c=0x01;RMI2cSpeed=100"
        ];

        blacklistedKernelModules = [ "nouveau" ];

        #extraModulePackages = [];

        kernelPackages = pkgs.linuxPackages_xanmod_latest;

        kernel.sysctl = {
            "fs.inotify.max_user_watches" = 2140000000;
        };

        swraid.enable = false;
    };

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

    virtualisation = {
        virtualbox.host.enable = true;
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
        device = "/dev/disk/by-uuid/8a9e0e21-ada8-4830-9836-3f9d678ac477";
    }];

    system.stateVersion = "24.05";
    time.timeZone = "America/Halifax";
    networking.hostName = "icarus";

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

    #environment.systemPackages = (with pkgs; []);


    #
    # Shared configurations.
    #
    imports = [
        ../shared/hardware.nix
        ../shared/configuration.nix
        ../shared/packages.nix
        ../shared/desktop-entries/mkvtoolnix.nix
    ];
}

# <> #
