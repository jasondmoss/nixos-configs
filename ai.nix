{ config, lib, pkgs, ... }:
# identity import removed — it was never referenced in this module.
# let
#    identity = import ./identity.nix;
# in
{
    environment = {
        variables = {
            CUDA_PATH = "${pkgs.cudaPackages.cudatoolkit}";
        };

        systemPackages = with pkgs; [
            # CUDA.
            cudaPackages.cudatoolkit
            cudaPackages.cudnn

            # AI tools.
            (pkgs.callPackage ./packages/claude-code {})
            claude-monitor
            realesrgan-ncnn-vulkan
        ];
    };

    services = {
        ollama = {
            enable = true;
            user = "ollama";
            group = config.services.ollama.user;
            home = "/home/ollama";
            models = "/home/me/Repository/ollama/models";
            host = "127.0.0.1";
            openFirewall = false;

            environmentVariables = {
                OLLAMA_NUM_PARALLEL= "8";
                OLLAMA_MAX_LOADED_MODELS = "1";
                CUDA_VISIBLE_DEVICES = "0";
                OLLAMA_GPU_OVERHEAD = "2147483648";
            };

            # https://ollama.com/library
            loadModels = [
                "deepseek-v4-pro:cloud"
                "glm-5.2:cloud"
            ];
        };

        # http://127.0.0.1:8080/
        open-webui = {
            enable = true;

            environment = {
                ANONYMIZED_TELEMETRY = "False";
                DO_NOT_TRACK = "True";
                SCARF_NO_ANALYTICS = "True";
                OLLAMA_API_BASE_URL = "http://127.0.0.1:11434/api";
                OLLAMA_BASE_URL = "http://127.0.0.1:11434";
            };

            package = (pkgs.callPackage ./packages/open-webui {});
        };
    };

    systemd.tmpfiles.rules = [
        "d /home/me/Repository/ollama 0755 ollama ollama -"
        "d /home/me/Repository/ollama/models 0755 ollama ollama -"
    ];

    # SD.Next systemd service.
    systemd = {
        services.ollama.serviceConfig = {
            DynamicUser = lib.mkForce false;
            PrivateUsers = lib.mkForce false;
            ProtectHome = lib.mkForce false;
        };
    };
}

# <> #
