{ config, lib, pkgs, ... }: {
    imports = [
        <nixos-hardware/common/gpu/nvidia/turing>
        ../packages/vaapi
    ];

    hardware = {
        graphics = {
            enable = true;
            enable32Bit = true;

            extraPackages = with pkgs; [
                libvdpau-va-gl
                libva-vdpau-driver
                nvidia-vaapi-driver
            ];
        };

        nvidia = {
            open = true;
            package = config.boot.kernelPackages.nvidiaPackages.beta;
            forceFullCompositionPipeline = true;
            modesetting.enable = true;
            nvidiaPersistenced = true;
            nvidiaSettings = true;
            gsp.enable = true;
            datacenter.enable = false;

            powerManagement = {
                enable = true;
                finegrained = false;
            };

            vaapi = {
                enable = true;
                firefox.enable = true;
            };
        };
    };

    services.xserver = {
        enable = false;
        videoDrivers = [ "nvidia" ];
        upscaleDefaultCursor = true;
        dpi = 192;
    };

    # NVIDIA & Wayland environment variables.
    environment.sessionVariables = {
        GBM_BACKEND = "nvidia-drm";
        __GLX_VENDOR_LIBRARY_NAME = "nvidia";
        LIBVA_DRIVER_NAME = "nvidia";

        # Performance tuning for RTX 2060.
        __GL_THREADED_OPTIMIZATION = "1";
        __GL_SHADER_CACHE = "1";
    };
}

# <> #
