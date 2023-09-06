{ config, lib, pkgs, modulesPath, ... }: {

  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot = {
    initrd = {
      availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];
      kernelModules = [ ];
    };

    kernelModules = [ "kvm-amd" ];
    extraModulePackages = [ ];
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

  networking = {
    useDHCP = lib.mkDefault true;

    interfaces = {
      wlp5s0.useDHCP = lib.mkDefault true;
      enp6s0.useDHCP = lib.mkDefault true;
      enp7s0.useDHCP = lib.mkDefault true;
    };
  };

  hardware = {
    cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

    nvidia = {
      package = config.boot.kernelPackages.nvidiaPackages.beta;
      open = true;
      nvidiaPersistenced = true;
      nvidiaSettings = true;
    };

    opengl = {
      enable = true;
      driSupport = true;

      extraPackages = with pkgs; [
        vaapiVdpau
        libvdpau-va-gl
        nvidia-vaapi-driver
      ];
    };

    pulseaudio.enable = false;
  };

}
