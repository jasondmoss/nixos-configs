{ lib, pkgs, ... }:

let
    # Scoped CUDA-enabled nixpkgs: builds only what we take from it
    # (ComfyUI's PyTorch stack) with CUDA, without flipping cudaSupport
    # globally and rebuilding half the system.
    pkgsCuda = import <nixpkgs> {
        config = {
            allowUnfree = true;
            cudaSupport = true;
        };
    };
in {
    imports = [
        # KRunner → Ollama runner (services.krunner-ollama).
        ../packages/krunner-ollama
    ];

    environment = {
        variables = {
            CUDA_PATH = "${pkgs.cudaPackages.cudatoolkit}";
        };

        sessionVariables = {
            HF_HOME = "/home/me/Repository/ai/huggingface";
            HF_HUB_DISABLE_TELEMETRY = "1";
        };

        systemPackages = with pkgs; [
            # CUDA.
            cudaPackages.cudatoolkit
            cudaPackages.cudnn

            # AI tools.
            (pkgs.callPackage ../packages/claude-code {})
            claude-monitor
            goose-cli
            opencode
            realesrgan-ncnn-vulkan

            # Voice pipeline (models live in ~/Repository/ai/).
            whisper-cpp-vulkan
            piper-tts
        ];
    };

    # Binary caches for CUDA builds (torch, magma, triton, ...) — avoid
    # multi-hour local compiles of the PyTorch stack.
    nix.settings = {
        substituters = [
            "https://nix-community.cachix.org"
            "https://cache.nixos-cuda.org"
        ];
        trusted-public-keys = [
            "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
            "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
        ];

        stalled-download-timeout = 60;
        connect-timeout = 15;
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
            OLLAMA_MAX_LOADED_MODELS = "3";
            OLLAMA_NUM_PARALLEL = "1";
            OLLAMA_FLASH_ATTENTION = "1";
            OLLAMA_KV_CACHE_TYPE = "q8_0";
            OLLAMA_CONTEXT_LENGTH = "32768";
            # Never proxy to ollama.com cloud models or web search: every
            # request this server answers is answered on this GPU.
            OLLAMA_NO_CLOUD = "1";
        };
    };

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

    systemd.services.ollama-embed-variant = {
        description = "Declare the qwen3-embedding:0.6b-8k Ollama variant";
        wantedBy = [ "multi-user.target" ];
        after = [ "ollama.service" ];
        requires = [ "ollama.service" ];
        environment = {
            OLLAMA_HOST = "127.0.0.1:11434";
            HOME = "%t/ollama-embed-variant";
        };
        serviceConfig = {
            Type = "oneshot";
            DynamicUser = true;
            RuntimeDirectory = "ollama-embed-variant";
            Restart = "on-failure";
            RestartSec = "30s";
            IPAddressDeny = "any";
            IPAddressAllow = "localhost";
        };
        unitConfig = {
            StartLimitIntervalSec = "10min";
            StartLimitBurst = 5;
        };
        script = ''
${pkgs.ollama-cuda}/bin/ollama create qwen3-embedding:0.6b-8k -f ${pkgs.writeText "Modelfile.qwen3-embedding-8k" ''
FROM qwen3-embedding:0.6b
PARAMETER num_ctx 8192
''}
        '';
    };

    users.users.me.extraGroups = [ "ollama" "comfyui" ];

    services.open-webui = {
        enable = true;
        port = 8180;
        environment = {
            OLLAMA_BASE_URL = "http://127.0.0.1:11434";
            WEBUI_AUTH = "False";
            ENABLE_OPENAI_API = "False";
            ENABLE_DIRECT_CONNECTIONS = "False";
            DEFAULT_MODELS = "gpt-oss:20b";
            WHISPER_LANGUAGE = "en";

            RAG_EMBEDDING_ENGINE = "ollama";
            RAG_OLLAMA_BASE_URL = "http://127.0.0.1:11434";
            RAG_EMBEDDING_MODEL = "qwen3-embedding:0.6b-8k";

            # Image generation/editing through the local ComfyUI (below).
            ENABLE_IMAGE_GENERATION = "True";
            IMAGE_GENERATION_ENGINE = "comfyui";
            COMFYUI_BASE_URL = "http://127.0.0.1:8188";

            # No phoning home: no update check, no community sharing, no
            # analytics.
            ENABLE_VERSION_UPDATE_CHECK = "False";
            ENABLE_COMMUNITY_SHARING = "False";
            ANONYMIZED_TELEMETRY = "False";
            DO_NOT_TRACK = "True";
            SCARF_NO_ANALYTICS = "True";
        };
    };

    # Ask the local model from KRunner: "ai <question>" (or "? <question>")
    # shows the first line of the answer; Enter copies the full answer, the
    # action button opens the question in Open WebUI. Module + package in
    # packages/krunner-ollama (systemd user unit, loopback-only client).
    services.krunner-ollama = {
        model = "qwen3.5:4b";
        ollamaUrl = "http://127.0.0.1:11434";
        webuiUrl = "http://localhost:8180";
        triggerWords = [ "ai" "?" ];
        onActivate = "copy";        # copy | open | both
        think = false;              # skip qwen3's thinking phase: answers in seconds
    };

    # Local image generation/editing (CUDA torch). Web UI + API on
    # 127.0.0.1:8188; also wired into Open WebUI's image engine.
    services.comfyui = {
        enable = true;
        listen = [ "127.0.0.1" ];
        package = pkgsCuda.comfyui.override {
            cudaPackages_13 = pkgsCuda.cudaPackages;
        };
    };

    systemd.services.comfyui = {
        unitConfig.RequiresMountsFor = [ "/home/me/Repository/ai" ];
        serviceConfig = {
            BindReadOnlyPaths = [
                "/home/me/Repository/ai/comfyui/models:/var/lib/comfyui/models"
            ];

            StateDirectoryMode = lib.mkForce "0750";
        };
    };
}

# <> #
