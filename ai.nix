{ lib, pkgs, ... }: {
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
            goose-cli
            opencode
            realesrgan-ncnn-vulkan

            # Voice pipeline (models live in ~/Repository/ai/).
            whisper-cpp
            piper-tts
        ];
    };

    # Local LLM inference server (OpenAI-compatible API on 127.0.0.1:11434).
    services.ollama = {
        enable = true;
        package = pkgs.ollama-cuda;

        # Static user (instead of DynamicUser) so model storage can live on
        # the /home NVMe for fast model loads. modelsDir defaults to
        # "${home}/models".
        user = "ollama";
        group = "ollama";
        home = "/home/ollama";

        environmentVariables = {
            OLLAMA_KEEP_ALIVE = "10m";      # Free VRAM shortly after use.
            OLLAMA_MAX_LOADED_MODELS = "1"; # One model at a time on 16 GiB.
            OLLAMA_FLASH_ATTENTION = "1";
        };
    };

    # The nixpkgs module hardcodes DynamicUser and ProtectHome=true, which
    # block a model store under /home even with a static user configured.
    # Relax only what's needed: run as the real ollama user and bind-mount
    # just its home into the unit's namespace — the rest of /home stays
    # hidden behind an empty tmpfs.
    systemd.services.ollama.serviceConfig = {
        DynamicUser = lib.mkForce false;
        ProtectHome = lib.mkForce "tmpfs";
        BindPaths = [ "/home/ollama" ];
    };

    # ReadWritePaths targets must exist before the unit starts.
    systemd.tmpfiles.rules = [
        "d /home/ollama        0775 ollama ollama -"
        "d /home/ollama/models 0775 ollama ollama -"
    ];

    # Read access to model files.
    users.users.me.extraGroups = [ "ollama" ];

    # Private ChatGPT-style web UI over Ollama — chat, RAG over documents,
    # model comparison. Localhost only; single-user (no login).
    services.open-webui = {
        enable = true;
        port = 8180;
        environment = {
            OLLAMA_BASE_URL = "http://127.0.0.1:11434";
            WEBUI_AUTH = "False";
            ENABLE_OPENAI_API = "False";
            ANONYMIZED_TELEMETRY = "False";
            DO_NOT_TRACK = "True";
            SCARF_NO_ANALYTICS = "True";
        };
    };
}

# <> #
