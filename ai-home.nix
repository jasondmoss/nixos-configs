# ai-home.nix
#
# Local-AI access layer for the home directory.
#
# Gives the *local* models (Ollama via Open WebUI, opencode, `talk -a`) a
# read-only view of /home/me with a declarative exclusion list, plus a
# full-text index over that same view and a meaning-based (embedding) index
# over the document folders. Nothing here talks to the internet.
#
#   ┌ Open WebUI / opencode ─────────────┐
#   │ MCP over streamable HTTP           │
#   └───────────────┬────────────────────┘
#           127.0.0.1:<port>/servers/<name>/mcp
#   ┌───────────────┴─────────── ai-home-mcp.service ────────────────────┐
#   │ mcp-proxy                                                          │
#   │   files    → mcp-server-filesystem /home/me   (list/read/search)   │
#   │   search   → home-search-mcp (Recoll index)   (full-text search)   │
#   │   semantic → home-semantic (sqlite-vec index) (search by meaning)  │
#   │   git      → mcp-server-git                   (status/log/diff)    │
#   │   docs     → markitdown-mcp                   (pdf/docx/xlsx → md) │
#   └────────────────────────────────────────────────────────────────────┘
#   ┌─────────────────────────── ai-home-index.service (timer) ──────────┐
#   │ recollindex  →  /var/lib/ai-home/recoll/xapiandb                   │
#   └────────────────────────────────────────────────────────────────────┘
#   ┌────────────────────── ai-home-semantic-index.service (timer) ──────┐
#   │ home-semantic index → Ollama qwen3-embedding:0.6b-8k @ 127.0.0.1:11434    │
#   │                     → /var/lib/ai-home/semantic/index.sqlite3      │
#   └────────────────────────────────────────────────────────────────────┘
#
# Every unit runs as the real user ("me") inside a systemd mount namespace:
#   ProtectHome=tmpfs + BindReadOnlyPaths=/home/me  → all of $HOME, read-only
#   InaccessiblePaths=<hiddenPaths>                  → excluded paths do not
#                                                      exist at all
#   IPAddressDeny=any / IPAddressAllow=localhost     → no egress, ever
# The exclusion is enforced by the kernel, not by tool configuration, and
# both indexes are built from inside the same namespace, so hidden paths
# are never indexed. Edit `services.ai-home.hiddenPaths` (below) to change
# what the AI can see; `unindexedPaths` keeps a tree readable but out of the
# indexes (media trees, client upload trees; fnmatch patterns where `*` also
# crosses `/`); `semanticPaths` picks the folders whose documents are
# embedded (the whole home would be too much for vectors).
#
# The semantic index is a passage store (sqlite-vec, a file under the state
# directory) rather than a vector database daemon on purpose: an in-process
# store lives inside the sandbox and is only readable by the unit's user,
# whereas a Qdrant/Chroma service would expose every indexed passage over an
# unauthenticated loopback API to any local process. Embeddings come from
# the local Ollama only — the sandbox cannot reach anything but loopback.
#
# Model side of the boundary: only local clients are wired to this. The
# cloud tools (claude-code, claude-desktop, gemini, antigravity) are NOT
# registered here on purpose — pointing them at these servers would send
# home-directory content off-machine.
#
{ config, lib, pkgs, ... }:

with lib;

let
    cfg = config.services.ai-home;

    homeSearchPython = pkgs.python3.withPackages (ps: [ ps.fastmcp ]);

    # Recoll's Python module ships inside the recoll package for the same
    # pkgs.python3 that fastmcp is built against.
    homeSearchMcp = pkgs.writeShellApplication {
        name = "home-search-mcp";
        runtimeInputs = [ homeSearchPython ];
        runtimeEnv.PYTHONPATH = "${cfg.recollPackage}/${pkgs.python3.sitePackages}";
        text = ''
exec python3 ${./packages/ai-home/home-search-mcp.py} "$@"
        '';
    };

    # Shell convenience: query the same index directly.
    aiSearch = pkgs.writeShellApplication {
        name = "ai-search";
        runtimeInputs = [ cfg.recollPackage ];
        text = ''
exec recollq -c ${cfg.stateDir}/recoll -A -n "''${AI_SEARCH_MAX:-20}" "$@"
        '';
    };

    abs = p: if hasPrefix "/" p then p else "${cfg.home}/${p}";
    hiddenAbs = map abs cfg.hiddenPaths;
    unindexedAbs = map abs cfg.unindexedPaths;

    # ─── Semantic (embedding) search ───────────────────────────────────────
    # One script, three entry points (index / serve / query), so documents
    # and queries are always embedded by the same code. Off when
    # semanticPaths is empty.
    semanticEnabled = cfg.semanticPaths != [];

    semanticPython = pkgs.python3.withPackages (ps: with ps; [
        fastmcp sqlite-vec ollama
        # Text extraction: pdf, docx, pptx, xlsx, odt/ods/odp, epub, html, rtf.
        pymupdf docx2txt python-pptx openpyxl odfpy ebooklib beautifulsoup4 striprtf
    ]);

    semanticConfig = pkgs.writeText "ai-home-semantic.json" (builtins.toJSON {
        db = "${cfg.stateDir}/semantic/index.sqlite3";
        home = cfg.home;
        roots = map abs cfg.semanticPaths;
        hidden = hiddenAbs;
        unindexed = unindexedAbs;
        skipped_names = cfg.skippedNames;
        suffixes = cfg.semanticSuffixes;
        model = cfg.semanticModel;
        ollama_url = cfg.ollamaUrl;
    });

    homeSemantic = pkgs.writeShellApplication {
        name = "home-semantic";
        runtimeInputs = [ semanticPython ];
        runtimeEnv.AI_HOME_SEMANTIC_CONFIG = "${semanticConfig}";
        text = ''
exec python3 ${./packages/ai-home/home-semantic.py} "$@"
        '';
    };

    # Shell convenience: `ai-semantic "what I am looking for" [-n 10] [-d dir]`.
    aiSemantic = pkgs.writeShellApplication {
        name = "ai-semantic";
        text = ''
exec ${homeSemantic}/bin/home-semantic query "$@"
        '';
    };

    recollConf = pkgs.writeText "recoll.conf" ''
topdirs = ${cfg.home}
followLinks = 0
indexallfilenames = 1
noaspell = 1
zipUseSkippedNames = 1
loglevel = ${toString cfg.indexLogLevel}
logfilename = stderr
idxflushmb = 256
textfilemaxmbs = 20
compressedfilemaxkbs = 100000
membermaxkbs = 50000
idxabsmlen = 300
# Entries are quoted (some contain spaces) and are fnmatch patterns; with
# FNM_PATHNAME off a "*" also matches "/", so one pattern covers any depth.
skippedPaths = ${concatMapStringsSep " " (p: "\"${p}\"") (hiddenAbs ++ unindexedAbs)}
skippedPathsFnmPathname = 0
skippedNames+ = ${concatStringsSep " " cfg.skippedNames}
noContentSuffixes+ = ${concatStringsSep " " cfg.noContentSuffixes}
    '';

    # Sub-mounts under $HOME must be present before the bind is created.
    homeMounts = filter (m: hasPrefix cfg.home m) (attrNames config.fileSystems);

    # The sandbox shared by every unit here.
    sandbox = {
        User = cfg.user;
        Group = cfg.group;
        StateDirectory = "ai-home";
        StateDirectoryMode = "0750";
        CacheDirectory = "ai-home";
        WorkingDirectory = cfg.stateDir;
        UMask = "0077";

        # Home directory: everything visible, read-only, minus hiddenPaths.
        ProtectHome = "tmpfs";
        BindReadOnlyPaths = [ cfg.home ];
        InaccessiblePaths = map (p: "-${p}") hiddenAbs;

        # No network egress: loopback only (MCP listener + nothing else).
        IPAddressDeny = "any";
        IPAddressAllow = "localhost";
        RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" "AF_NETLINK" ];

        # Standard hardening.
        NoNewPrivileges = true;
        PrivateTmp = true;
        PrivateDevices = true;
        ProtectSystem = "strict";
        ProtectProc = "invisible";
        ProcSubset = "all"; # /proc/meminfo, /proc/cpuinfo for python/node
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        LockPersonality = true;
        RemoveIPC = true;
        CapabilityBoundingSet = [ "" ];
        SystemCallArchitectures = "native";
        SystemCallFilter = [ "@system-service" "~@privileged" ];
    };

    sandboxEnv = {
        HOME = cfg.stateDir;
        XDG_CACHE_HOME = "/var/cache/ai-home";
        RECOLL_CONFDIR = "${cfg.stateDir}/recoll";
        AI_HOME_ROOT = cfg.home;
        # fastmcp servers: no startup banner on stderr and no release check
        # against PyPI (it would be blocked by IPAddressDeny anyway).
        FASTMCP_SHOW_SERVER_BANNER = "false";
        FASTMCP_CHECK_FOR_UPDATES = "off";
    };

    # Named stdio servers behind mcp-proxy. Each becomes
    # http://127.0.0.1:<port>/servers/<name>/mcp
    namedServers = {
        files  = "${pkgs.mcp-server-filesystem}/bin/mcp-server-filesystem ${cfg.home}";
        search = "${homeSearchMcp}/bin/home-search-mcp";
        git    = "${pkgs.mcp-server-git}/bin/mcp-server-git";
        docs   = "${pkgs.markitdown-mcp}/bin/markitdown-mcp";
    } // optionalAttrs semanticEnabled {
        semantic = "${homeSemantic}/bin/home-semantic serve";
    };

    serverUrl = name: "http://127.0.0.1:${toString cfg.port}/servers/${name}/mcp";

    # Open WebUI "External Tools" entries (Admin → Settings → External Tools).
    webuiConnections = mapAttrsToList (name: description: {
        type = "mcp";
        url = serverUrl name;
        path = "";
        auth_type = "none";
        key = "";
        config = { enable = true; };
        info = {
            id = "ai-home-${name}";
            name = "Home: ${name}";
            inherit description;
        };
    }) ({
        files  = "Read-only view of ${cfg.home} (list, read, glob-search, file info).";
        search = "Full-text search over ${cfg.home} (Recoll index).";
        git    = "Git status/log/diff/show for repositories under ${cfg.home}.";
        docs   = "Convert PDF/Office/HTML files under ${cfg.home} to Markdown (file:// URIs).";
    } // optionalAttrs semanticEnabled {
        semantic = "Search by meaning (local embeddings) over ${concatStringsSep ", " cfg.semanticPaths}: topics and descriptions rather than exact words.";
    });
in {
    options.services.ai-home = {
        enable = mkOption {
            type = types.bool;
            default = true;
            description = "Sandboxed read-only home-directory access + search for local AI clients.";
        };

        user = mkOption { type = types.str; default = "me"; };
        group = mkOption { type = types.str; default = "users"; };
        home = mkOption { type = types.str; default = "/home/me"; };
        stateDir = mkOption { type = types.str; default = "/var/lib/ai-home"; readOnly = true; };

        port = mkOption {
            type = types.port;
            default = 8300;
            description = "Loopback port for the MCP HTTP endpoints.";
        };

        recollPackage = mkPackageOption pkgs "recoll-nox" { };

        hiddenPaths = mkOption {
            type = types.listOf types.str;
            description = ''
                Paths (relative to `home`, or absolute) that must not exist for
                the AI: enforced with systemd InaccessiblePaths and excluded from
                the search index. Missing entries are ignored.
            '';
            default = [
                # Keys, credentials, wallets, certificates.
                ".ssh" ".gnupg" ".pki" ".cert" ".docker" ".mcp-auth" ".megarc"
                ".netrc" ".npmrc" ".yarnrc" ".wget-hsts" ".lando/certs"
                ".config/1Password" ".config/op" ".config/gh" ".config/ngrok"
                ".config/composer/auth.json" ".config/JetBrains" ".local/share/JetBrains"
                ".local/share/kwalletd" ".local/share/keyrings" ".local/share/mkcert"
                ".local/share/proton-drive-cli" ".local/share/Proton"
                ".config/Proton" ".config/Proton Mail"

                # Shell / REPL histories.
                ".bash_history" ".lesshst" ".node_repl_history" ".python_history"
                ".local/share/nvim/shada"

                # Browser profiles: cookies, sessions, saved logins.
                ".mozilla" ".tor" ".mullvad"
                ".config/google-chrome" ".config/google-chrome-beta"
                ".config/google-chrome-unstable" ".config/google-chrome-headless"
                ".config/chromium" ".config/BraveSoftware" ".config/opera"
                ".config/microsoft-edge" ".config/microsoft-edge-dev"
                ".config/vivaldi" ".config/vivaldi-snapshot" ".config/wavebox"
                ".config/nyxt" ".local/share/nyxt" ".config/Ladybird" ".local/share/Ladybird"
                ".config/figma" ".config/figma-linux"

                # AI assistants' own state: chat logs, API tokens.
                ".claude" ".claude.json" ".claude-personal" ".claudecodebrowser"
                ".gemini" ".config/gemini" ".config/Claude" ".config/opencode"
                ".local/share/opencode" ".local/share/claude" ".local/share/claude-ai"
                ".local/share/gemini-desktop" ".local/share/oterm" ".junie" ".ai"

                # Messaging, mail, sync internals, torrents.
                ".config/Standard Notes" ".config/kdeconnect" ".local/share/kpeoplevcard"
                ".config/akonadi" ".local/share/akonadi"
                ".config/qBittorrent" ".local/share/qBittorrent"

                # Caches and machine noise (not secret, just useless and huge).
                ".cache" ".local/share/Trash" ".local/share/baloo" ".nv"
                ".compose-cache" ".npm" ".cargo/registry" ".var" ".java"
                ".local/share/containers" ".local/share/flatpak" "node_modules"
            ];
        };

        unindexedPaths = mkOption {
            type = types.listOf types.str;
            description = ''
                Readable through the filesystem tools but left out of both
                indexes (large binary trees; filenames are still reachable
                with the filesystem `search_files` glob tool). Entries are
                fnmatch patterns in which `*` also matches `/`, so
                `Repository/work/*/sites/*/files` covers a Drupal upload
                tree at any depth.
            '';
            default = [
                "Videos" "Mega/Camera Uploads" "Repository/ai"
                # Client sites' user uploads (Drupal public and private
                # files: images, derivatives, attachments) — hundreds of
                # thousands of files that are not ours to search.
                "Repository/work/*/sites/*/files"
                "Repository/work/*/private"
                # Third-party Drupal code vendored per project (a copy of
                # core and the contrib modules/themes/libraries in each of
                # ~40 client checkouts, >1M files); custom code stays in.
                "Repository/work/*/web/core"
                "Repository/work/*/web/libraries"
                "Repository/work/*/modules/contrib"
                "Repository/work/*/themes/contrib"
            ];
        };

        skippedNames = mkOption {
            type = types.listOf types.str;
            description = "Directory/file name patterns skipped by the indexer, anywhere in the tree (appended to Recoll's defaults).";
            default = [
                "node_modules" "vendor" "bower_components" ".idea" ".vscode"
                ".mypy_cache" ".ruff_cache" ".venv" "venv" "dist" "build" "out"
                "target" ".next" ".nuxt" ".turbo" ".parcel-cache" ".gradle" ".npm"
                ".yarn" ".pnpm-store" "coverage" "result" "result-*" ".ddev" ".lando"
                "*.min.js" "*.min.css" "*.map" "*.lock" "package-lock.json"
                "yarn.lock" "composer.lock" "*.log" "*.tmp" "*.swp" "*.bak"
                ".DS_Store" "Thumbs.db"
            ];
        };

        noContentSuffixes = mkOption {
            type = types.listOf types.str;
            description = "File suffixes indexed by name only (no content extraction).";
            default = [
                # Video (metadata extraction is slow and low-value).
                ".mp4" ".mkv" ".avi" ".mov" ".webm" ".m4v" ".ts" ".wmv"
                # Disk images, archives, packages.
                ".iso" ".img" ".qcow2" ".vdi" ".vmdk" ".zip" ".7z" ".rar" ".tar"
                ".gz" ".xz" ".zst" ".bz2" ".tgz" ".jar" ".deb" ".rpm" ".AppImage"
                # AI model weights.
                ".gguf" ".safetensors" ".ckpt" ".pt" ".pth" ".onnx" ".bin"
                # Build products, binaries, databases, fonts, design sources.
                ".so" ".o" ".a" ".class" ".pyc" ".wasm" ".exe" ".dll"
                ".db" ".sqlite" ".sqlite3" ".ldb"
                ".woff" ".woff2" ".ttf" ".otf" ".eot"
                ".psd" ".xcf" ".kra" ".blend"
            ];
        };

        indexSchedule = mkOption {
            type = types.str;
            default = "*-*-* 03:30:00";
            description = "systemd OnCalendar for the incremental re-index. Run `systemctl start ai-home-index` for an immediate pass.";
        };

        indexLogLevel = mkOption { type = types.ints.between 0 6; default = 2; };

        semanticPaths = mkOption {
            type = types.listOf types.str;
            description = ''
                Folders (relative to `home`, or absolute) whose documents are
                embedded for meaning-based search (`semantic_search` tool,
                `ai-semantic` shell helper). Missing entries are ignored;
                `hiddenPaths`, `unindexedPaths` and `skippedNames` apply here
                too. An empty list disables the semantic index, its timer and
                its MCP server.
            '';
            default = [ "Documents" "Mega/Documents" "Mega/Work" ];
        };

        semanticSuffixes = mkOption {
            type = types.listOf types.str;
            description = ''
                File suffixes to embed. pdf, docx, pptx, xlsx, odt/ods/odp,
                epub, html/htm and rtf have dedicated extractors; anything
                else added here is read as plain UTF-8 text.
            '';
            default = [
                ".pdf" ".docx" ".pptx" ".xlsx" ".odt" ".ods" ".odp" ".epub"
                ".rtf" ".html" ".htm" ".md" ".markdown" ".txt" ".csv"
            ];
        };

        semanticModel = mkOption {
            type = types.str;
            # 8k-context variant declared in ai.nix (ollama-embed-variant).
            default = "qwen3-embedding:0.6b-8k";
            description = ''
                Ollama embedding model (must already be pulled:
                `ollama pull <model>`). Changing it rebuilds the index on the
                next run.
            '';
        };

        semanticSchedule = mkOption {
            type = types.str;
            default = cfg.indexSchedule;
            defaultText = literalExpression "config.services.ai-home.indexSchedule";
            description = ''
                systemd OnCalendar for the incremental embedding pass
                (independent of the Recoll pass). Run
                `systemctl start ai-home-semantic-index` for an immediate one.
            '';
        };

        ollamaUrl = mkOption {
            type = types.str;
            default = "http://127.0.0.1:${toString config.services.ollama.port}";
            defaultText = literalExpression ''"http://127.0.0.1:''${toString config.services.ollama.port}"'';
            description = ''
                Local Ollama endpoint used for embeddings. The sandbox only
                allows loopback, so a non-local address cannot work here by
                construction.
            '';
        };

        registerWithOpenWebUI = mkOption {
            type = types.bool;
            default = config.services.open-webui.enable;
            description = "Register the MCP servers as External Tools in the local Open WebUI on boot (idempotent).";
        };
    };

    config = mkIf cfg.enable {
        environment.systemPackages = [ aiSearch cfg.recollPackage ]
            ++ optional semanticEnabled aiSemantic;

        # ─── MCP endpoint ──────────────────────────────────────────────────
        systemd.services.ai-home-mcp = {
            description = "Local-AI home directory access (MCP over HTTP, sandboxed)";
            wantedBy = [ "multi-user.target" ];
            after = [ "network.target" ];
            unitConfig.RequiresMountsFor = homeMounts;
            environment = sandboxEnv;
            path = [ pkgs.coreutils ];
            serviceConfig = sandbox // {
                Type = "simple";
                Restart = "on-failure";
                RestartSec = "5s";
                ExecStartPre = pkgs.writeShellScript "ai-home-mcp-pre" ''
mkdir -p ${cfg.stateDir}/recoll
install -m 0644 ${recollConf} ${cfg.stateDir}/recoll/recoll.conf
                '';
                ExecStart = concatStringsSep " " ([
                    "${pkgs.mcp-proxy}/bin/mcp-proxy"
                    "--host 127.0.0.1 --port ${toString cfg.port}"
                    "--pass-environment"
                ] ++ mapAttrsToList (n: c: "--named-server ${n} ${escapeShellArg c}") namedServers);
            };
        };

        # ─── Full-text index ───────────────────────────────────────────────
        systemd.services.ai-home-index = {
            description = "Local-AI home directory full-text index (Recoll, sandboxed)";
            unitConfig.RequiresMountsFor = homeMounts;
            environment = sandboxEnv;
            path = [ pkgs.coreutils cfg.recollPackage ];
            serviceConfig = sandbox // {
                Type = "oneshot";
                Nice = 19;
                IOSchedulingClass = "idle";
                CPUWeight = 20;
                MemoryMax = "6G";
                ExecStartPre = pkgs.writeShellScript "ai-home-index-pre" ''
mkdir -p ${cfg.stateDir}/recoll
install -m 0644 ${recollConf} ${cfg.stateDir}/recoll/recoll.conf
                '';
                ExecStart = "${cfg.recollPackage}/bin/recollindex -c ${cfg.stateDir}/recoll";
            };
        };

        systemd.timers.ai-home-index = {
            wantedBy = [ "timers.target" ];
            timerConfig = {
                OnCalendar = cfg.indexSchedule;
                OnBootSec = "15min";
                Persistent = true;
                RandomizedDelaySec = "10min";
            };
        };

        # ─── Semantic (embedding) index ────────────────────────────────────
        # Incremental: only new/changed files are re-embedded, removed ones
        # are dropped. The first pass over a large PDF collection can take an
        # hour; progress is committed per file, so an interrupted run resumes.
        systemd.services.ai-home-semantic-index = mkIf semanticEnabled {
            description = "Local-AI home directory semantic index (Ollama embeddings → sqlite-vec, sandboxed)";
            unitConfig.RequiresMountsFor = homeMounts;
            # Ollama does the embedding work. Deliberately *not* ordered after
            # ai-home-index: a first Recoll pass over the whole home takes
            # hours, and a start job queued behind it looks like a hung
            # indexer (nothing in the journal, no database).
            after = optional config.services.ollama.enable "ollama.service";
            wants = optional config.services.ollama.enable "ollama.service";
            environment = sandboxEnv;
            path = [ pkgs.coreutils ];
            serviceConfig = sandbox // {
                Type = "oneshot";
                Nice = 19;
                IOSchedulingClass = "idle";
                CPUWeight = 20;
                MemoryMax = "4G";
                ExecStart = "${homeSemantic}/bin/home-semantic index";
            };
        };

        systemd.timers.ai-home-semantic-index = mkIf semanticEnabled {
            wantedBy = [ "timers.target" ];
            timerConfig = {
                OnCalendar = cfg.semanticSchedule;
                OnBootSec = "30min";
                Persistent = true;
                RandomizedDelaySec = "10min";
            };
        };

        # ─── Open WebUI registration ───────────────────────────────────────
        # Open WebUI keeps tool-server connections in its database (the
        # TOOL_SERVER_CONNECTIONS env var only seeds a fresh install), so
        # register through the API instead: replace every entry whose
        # info.id starts with "ai-home-" (ours), never touch anything the
        # user added in the UI. With WEBUI_AUTH=False the backend signs in a
        # fixed built-in admin.
        systemd.services.ai-home-webui-register = mkIf cfg.registerWithOpenWebUI {
            description = "Register ai-home MCP servers with Open WebUI";
            wantedBy = [ "multi-user.target" ];
            after = [ "open-webui.service" "ai-home-mcp.service" ];
            wants = [ "open-webui.service" "ai-home-mcp.service" ];
            path = with pkgs; [ curl jq coreutils ];
            serviceConfig = {
                Type = "oneshot";
                DynamicUser = true;
                Restart = "on-failure";
                RestartSec = "30s";
                IPAddressDeny = "any";
                IPAddressAllow = "localhost";
                PrivateTmp = true;
                ProtectSystem = "strict";
                ProtectHome = true;
                NoNewPrivileges = true;
            };
            unitConfig = {
                StartLimitIntervalSec = "10min";
                StartLimitBurst = 10;
            };
            script = ''
set -euo pipefail
base="http://127.0.0.1:${toString config.services.open-webui.port}"
want='${builtins.toJSON webuiConnections}'

for i in $(seq 1 30); do
    curl -fsS --max-time 5 "$base/health" >/dev/null 2>&1 && break
    sleep 2
done

token=$(curl -fsS --max-time 10 -X POST "$base/api/v1/auths/signin" \
    -H 'content-type: application/json' \
    -d '{"email":"admin@localhost","password":"admin"}' | jq -r '.token // empty')
[ -n "$token" ] || { echo "no session token from Open WebUI"; exit 1; }
auth=(-H "authorization: Bearer $token" -H 'content-type: application/json')

have=$(curl -fsS --max-time 10 "''${auth[@]}" "$base/api/v1/configs/tool_servers" \
    | jq -c '.TOOL_SERVER_CONNECTIONS // []')

# Replace our own entries (info.id "ai-home-*", so servers that were disabled
# in the config disappear too), keep everything else.
merged=$(jq -cn --argjson have "$have" --argjson want "$want" '
    ($have | map(select(((.info.id // "") | startswith("ai-home-")) | not))) + $want')

if [ "$(echo "$have" | jq -S .)" = "$(echo "$merged" | jq -S .)" ]; then
    echo "Open WebUI tool servers already up to date"
    exit 0
fi

curl -fsS --max-time 20 "''${auth[@]}" -X POST "$base/api/v1/configs/tool_servers" \
    -d "$(jq -cn --argjson c "$merged" '{TOOL_SERVER_CONNECTIONS: $c}')" >/dev/null
echo "registered ${toString (length webuiConnections)} ai-home MCP servers with Open WebUI"
            '';
        };
    };
}

# <> #
