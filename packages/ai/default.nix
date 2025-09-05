{ pkgs, ... }: {

    services = {
        ollama = {
            enable = false;
            acceleration = "cuda";
#            user = null;
#            group = null;
#            group = "config.services.ollama.user";
#            host = "0.0.0.0:11434";

#            environmentVariables = {
#                OLLAMA_NUM_PARALLEL= "8";
#                OLLAMA_MAX_LOADED_MODELS = "1";
#                CUDA_VISIBLE_DEVICES = "0";
#                OLLAMA_GPU_OVERHEAD = "2147483648";
#            };

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
#        };
    };

    environment.systemPackages = with pkgs; [
        oterm
    ];

}
