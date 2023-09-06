{
  config, lib, pkgs, modulesPath, ...
}:
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

    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
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

    wireless = {
      enable = true;

      userControlled = {
        enable = true;
        group = "wheel";
      };

      networks = {
        Skynet = {
          psk = "96Hgpqo5$%h#5mv#6^eac^KT5q3S@$ZP2Mp7";
        };
      };
    };

    interfaces = {
      enp3s0.useDHCP = lib.mkDefault true;
      wlo1.useDHCP = lib.mkDefault true;
    };
  };


  hardware = {
    cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

    nvidia = {
      modesetting.enable = true;
      open = true;
      nvidiaPersistenced = true;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.beta;

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


  powerManagement.cpuFreqGovernor = lib.mkDefault "performance";


  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
