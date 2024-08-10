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
                #egl-wayland
                intel-media-driver
                #libdrm
                #libGL
                #libglvnd
                #libva
                #libva-utils
                #libva1
                libvdpau-va-gl
                #mesa
                nvidia-vaapi-driver
                vaapiIntel
                vaapiVdpau
                #virtualgl
                vulkan-tools
                vulkan-validation-layers
            ];
        };

        nvidia-container-toolkit.enable = true;

        pulseaudio.enable = false;
    };

    virtualisation.docker = {
        enable = true;
        enableOnBoot = true;
    };

    powerManagement.cpuFreqGovernor = lib.mkDefault "performance";
}
