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

    # Binary caches for CUDA builds (torch, magma, triton, ...) — avoid
    # multi-hour local compiles of the PyTorch stack.
    nix.settings = {
        substituters = [
            "https://nix-community.cachix.org"
            "https://cuda-maintainers.cachix.org"
        ];
        trusted-public-keys = [
            "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
            "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
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

    # Read access to model files (ollama) and generated images (comfyui).
    users.users.me.extraGroups = [ "ollama" "comfyui" ];

    # Private ChatGPT-style web UI over Ollama — chat, RAG over documents,
    # model comparison. Localhost only; single-user (no login).
    services.open-webui = {
        enable = true;
        port = 8180;
        environment = {
            OLLAMA_BASE_URL = "http://127.0.0.1:11434";
            WEBUI_AUTH = "False";
            ENABLE_OPENAI_API = "False";
            # Never default to the embeddings-only model (can't chat).
            DEFAULT_MODELS = "qwen3:14b";
            WHISPER_LANGUAGE = "en";
            ANONYMIZED_TELEMETRY = "False";
            DO_NOT_TRACK = "True";
            SCARF_NO_ANALYTICS = "True";
        };
    };

    # Local image generation/editing (CUDA torch). Web UI + API on
    # 127.0.0.1:8188; also wired into Open WebUI's image engine.
    services.comfyui = {
        enable = true;
        # Module default also binds ::1, which crash-loops the service on
        # this system (IPv6 disabled in networking.nix).
        listen = [ "127.0.0.1" ];
        # Un-pin ComfyUI's cudaPackages_13: its libnvshmem is broken on the
        # current channel commit (CCCL header errors), and the CUDA-13 torch
        # stack isn't in any binary cache — the default-CUDA torch/magma/
        # triton are all cached by nix-community. Costs: ComfyUI's CUDA-13-
        # only quant ops are disabled at runtime. Revisit after a channel
        # update fixes libnvshmem upstream.
        package = pkgsCuda.comfyui.override {
            cudaPackages_13 = pkgsCuda.cudaPackages;
        };
    };

    systemd.services.comfyui = {
        unitConfig.RequiresMountsFor = [ "/home/me/Repository/ai" ];
        serviceConfig = {
            # Model files stay under ~/Repository/ai/ (user-managed,
            # read-only to the service); outputs stay in the state dir.
            BindReadOnlyPaths = [
                "/home/me/Repository/ai/comfyui/models:/var/lib/comfyui/models"
            ];
            # Let the "me" user (comfyui group) browse generated images.
            StateDirectoryMode = lib.mkForce "0750";
        };
    };
}

# <> #
