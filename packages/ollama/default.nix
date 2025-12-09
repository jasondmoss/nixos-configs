{ lib, pkgs, ... }: {
    systemd.services.ollama.serviceConfig = {
        DynamicUser = lib.mkForce false;
        PrivateUsers = lib.mkForce false;
        ProtectHome = lib.mkForce false;
    };

    services = {
        ollama = {
            enable = true;
#            acceleration = "cuda";
            user = "ollama";
            group = "config.services.ollama.user";
            home = "/home/ollama";
            host = "0.0.0.0";
            openFirewall = true;

            environmentVariables = {
                OLLAMA_NUM_PARALLEL= "8";
                OLLAMA_MAX_LOADED_MODELS = "1";
                CUDA_VISIBLE_DEVICES = "0";
                OLLAMA_GPU_OVERHEAD = "2147483648";
            };

            # https://ollama.com/library
            loadModels = [ "deepseek-r1:32b" ];
        };

#        open-webui = {
#            enable = true;
#
#            environment = {
#                ANONYMIZED_TELEMETRY = "False";
#                DO_NOT_TRACK = "True";
#                SCARF_NO_ANALYTICS = "True";
#                OLLAMA_API_BASE_URL = "http://127.0.0.1:11434/api";
#                OLLAMA_BASE_URL = "http://127.0.0.1:11434";
#            };
#
#            package = (pkgs.callPackage ../open-webui {});
#        };
    };

    environment.systemPackages = with pkgs; [
        oterm
    ];
}
