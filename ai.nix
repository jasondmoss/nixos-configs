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
        # KRunner → Ollama runner (services.krunner-ollama, configured below).
        ./packages/krunner-ollama
    ];

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

            # Voice pipeline (models live in ~/Repository/ai/). Vulkan build:
            # runs transcription on the GPU (works on the NVIDIA driver) and is
            # in the binary cache, unlike a CUDA-enabled whisper-cpp.
            whisper-cpp-vulkan
            piper-tts
        ];
    };

    # Binary caches for CUDA builds (torch, magma, triton, ...) — avoid
    # multi-hour local compiles of the PyTorch stack.
    #
    # The CUDA cache moved off Cachix (Nov 2025) to the Hydra-backed
    # cache.nixos-cuda.org. The retired cuda-maintainers.cachix.org now
    # answers *every* narinfo lookup with HTTP 401 instead of 404, and nix
    # treats 401 as a hard error rather than a cache miss — so any build that
    # happened to query it aborted with "Binary cache cuda-maintainers doesn't
    # exist or you're not authorized to access it", even for paths it never
    # held. Not a private cache we lost access to: it serves nothing at all.
    nix.settings = {
        substituters = [
            "https://nix-community.cachix.org"
            "https://cache.nixos-cuda.org"
        ];
        trusted-public-keys = [
            "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
            "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
        ];

        # cache.nixos-cuda.org is a single self-hosted Hydra box, not a CDN,
        # and it drops connections mid-transfer. Nix's default 300s stall
        # timeout doesn't always catch it: a socket left in CLOSE-WAIT with
        # unread bytes doesn't look stalled, so a fetch of the multi-GiB torch
        # closure can park in poll() indefinitely. Fail fast and retry instead
        # — a spurious retry costs seconds, a hang costs the whole rebuild.
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
            # Main model + the small assistant model (KRunner/talk) + the
            # embedding model resident together; otherwise every retrieval or
            # quick question swaps the 12 GiB main model out and back in.
            # Ollama only co-loads what fits, evicting least-recently-used.
            OLLAMA_MAX_LOADED_MODELS = "3";
            OLLAMA_NUM_PARALLEL = "1";
            OLLAMA_FLASH_ATTENTION = "1";
            # 8-bit K/V cache halves context memory at no visible quality
            # cost (needs flash attention); 32k context so agent/RAG turns
            # don't silently truncate. qwen3:14b + 32k q8 KV ≈ 12 GiB.
            OLLAMA_KV_CACHE_TYPE = "q8_0";
            OLLAMA_CONTEXT_LENGTH = "32768";
            # Never proxy to ollama.com cloud models or web search: every
            # request this server answers is answered on this GPU.
            OLLAMA_NO_CLOUD = "1";
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

    # Embedding model variant with an 8k context. Ollama sizes a model's K/V
    # cache from its context length, and with OLLAMA_CONTEXT_LENGTH=32768 the
    # 639 MB embedder claimed 4 GiB of VRAM (measured 2026-09-13); RAG chunks
    # are a few hundred tokens, so 8k is ample: the variant loads at 2.4 GiB
    # (f16 cache; ~2 GiB with the q8 cache above).
    # `ollama create` only writes a manifest that shares the pulled blobs;
    # re-run on every boot (idempotent) so the name always exists.
    systemd.services.ollama-embed-variant = {
        description = "Declare the qwen3-embedding:0.6b-8k Ollama variant";
        wantedBy = [ "multi-user.target" ];
        after = [ "ollama.service" ];
        requires = [ "ollama.service" ];
        environment.OLLAMA_HOST = "127.0.0.1:11434";
        serviceConfig = {
            Type = "oneshot";
            DynamicUser = true;
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

    # Read access to model files (ollama) and generated images (comfyui).
    users.users.me.extraGroups = [ "ollama" "comfyui" ];

    # Private ChatGPT-style web UI over Ollama — chat, RAG over documents,
    # model comparison. Localhost only; single-user (no login).
    services.open-webui = {
        enable = true;
        port = 8180;
        # NOTE: most of these are Open WebUI "PersistentConfig" values — they
        # seed a fresh database and are then owned by Admin → Settings in the
        # UI. Change them there once the instance exists (or set
        # ENABLE_PERSISTENT_CONFIG=False to make this block authoritative).
        environment = {
            OLLAMA_BASE_URL = "http://127.0.0.1:11434";
            WEBUI_AUTH = "False";
            ENABLE_OPENAI_API = "False";
            ENABLE_DIRECT_CONNECTIONS = "False";
            # Default chat model: gpt-oss:20b measured 2x faster than qwen3:14b
            # at 32k context and fully on-GPU (2026-09-13). gemma4:12b is the
            # multimodal candidate to compare against in the UI.
            DEFAULT_MODELS = "gpt-oss:20b";
            WHISPER_LANGUAGE = "en";

            # RAG embeddings on the GPU through Ollama instead of the default
            # CPU sentence-transformers model (which is also a HuggingFace
            # download at first use). Re-index existing Knowledge after
            # switching the engine.
            RAG_EMBEDDING_ENGINE = "ollama";
            RAG_OLLAMA_BASE_URL = "http://127.0.0.1:11434";
            # qwen3-embedding:0.6b (1024 dims; nomic-embed-text cut chunks at
            # 2k tokens) through the 8k-context variant declared below.
            # Existing Knowledge must be re-indexed after the switch
            # (Admin → Settings → Documents).
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
        # Small multimodal model: sub-second first token, co-resident with
        # the main model (see OLLAMA_MAX_LOADED_MODELS).
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
