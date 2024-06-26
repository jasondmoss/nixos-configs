{ config, lib, pkgs, modulesPath, ... }:
{
    imports = [
        (modulesPath + "/installer/scan/not-detected.nix")
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
        graphics = {
            enable = true;
            enable32Bit = true;

            extraPackages = with pkgs; [
                intel-media-driver
                libvdpau-va-gl
                nvidia-vaapi-driver
                vaapiIntel
                vaapiVdpau
                vulkan-validation-layers
            ];
        };

        pulseaudio.enable = false;
    };

    virtualisation.docker = {
        enable = true;
        enableOnBoot = true;
        enableNvidia = true;
    };

    powerManagement.cpuFreqGovernor = lib.mkDefault "performance";
}
