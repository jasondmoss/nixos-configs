{ config, lib, pkgs, ... }:

#-- krunner-ollama — ask the local Ollama model from KRunner.
#--
#--   Alt+Space  →  "ai what is the capital of Canada"
#--                 ┌─────────────────────────────────────────────────────┐
#--                 │ Ottawa is the capital of Canada.                    │
#--                 │ qwen3:14b · 1 line · Enter copies the answer   [🌐] │
#--                 └─────────────────────────────────────────────────────┘
#--   Enter copies the full answer to the clipboard (default, see
#--   `onActivate`); the action button opens the question in Open WebUI as
#--   http://localhost:8180/?q=<question>. A bare trigger word offers to open
#--   Open WebUI without a question.
#--
#-- Pieces: the runner (`package.nix`, Python on dbus-python + GLib) is a
#-- session-bus service implementing org.kde.krunner1; KRunner finds it via
#-- share/krunner/dbusplugins/*.desktop and can D-Bus-activate it through a
#-- share/dbus-1/services entry that hands off to the user unit below. Both
#-- files are installed system-wide (environment.systemPackages), the unit
#-- runs in the user manager with graphical-session.target.
#--
#-- Network boundary. The runner only ever connects to `ollamaUrl`, whose
#-- host must resolve to loopback (checked at startup, connection made by
#-- resolved IP, no proxy variables consulted); Open WebUI is opened via the
#-- OpenURI desktop portal, so the browser — not this process — fetches it.
#-- The unit additionally limits address families to unix/inet via seccomp.
#-- NOTE: IPAddressDeny=/IPAddressAllow= are *not* enforced by the
#-- unprivileged user manager (verified 2026-09-13: a user unit with
#-- IPAddressDeny=any still reached the internet — cgroup BPF programs need
#-- CAP_NET_ADMIN), so unlike ai-home.nix's system units they are left out
#-- here rather than declared as false assurance. Running the runner as a
#-- system unit under user `me` (ai-home.nix pattern) would restore the
#-- kernel-enforced boundary at the cost of D-Bus activation.
#--
#-- Trigger words: `?` is also the prefix of KRunner's own help runner; that
#-- one only matches when the text after `?` names a runner, so mixing is
#-- rare, but drop `?` from `triggerWords` if it gets in the way.

with lib;

let
    cfg = config.services.krunner-ollama;

    busName = "org.jdmlabs.krunner.ollama";
    unitName = "krunner-ollama.service";
in {
    options.services.krunner-ollama = {
        enable = mkOption {
            type = types.bool;
            default = true;
            description = "KRunner runner that asks the local Ollama server.";
        };

        package = mkOption {
            type = types.package;
            default = pkgs.callPackage ./package.nix {
                inherit busName unitName;
                inherit (cfg) triggerWords;
            };
            defaultText = literalExpression "pkgs.callPackage ./package.nix { ... }";
            description = "Runner program plus KRunner plugin metadata and D-Bus activation file.";
        };

        model = mkOption {
            type = types.str;
            default = "qwen3:14b";
            description = "Ollama model that answers the queries.";
        };

        ollamaUrl = mkOption {
            type = types.str;
            default = "http://127.0.0.1:11434";
            description = ''
                Ollama base URL. The host must resolve to loopback addresses only;
                the runner refuses to start otherwise.
            '';
        };

        webuiUrl = mkOption {
            type = types.str;
            default = "http://localhost:8180";
            description = "Open WebUI base URL; questions open as `<url>/?q=<question>`.";
        };

        triggerWords = mkOption {
            type = types.listOf types.str;
            default = [ "ai" "?" ];
            description = ''
                Words that route a KRunner query here when typed first, followed
                by a space (`ai what is …`). No spaces or commas inside a word.
            '';
        };

        onActivate = mkOption {
            type = types.enum [ "copy" "open" "both" ];
            default = "copy";
            description = ''
                What Enter does on the answer: copy the full answer to the
                clipboard, open the question in Open WebUI, or both. Whatever
                Enter does not do stays available as an action button.
            '';
        };

        systemPrompt = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "System prompt; null keeps the runner's built-in one (plain text, gist first).";
        };

        numPredict = mkOption {
            type = types.int;
            default = 512;
            description = "Token cap per answer (Ollama `num_predict`; -1 = unlimited).";
        };

        think = mkOption {
            type = types.nullOr types.bool;
            default = false;
            description = ''
                Value of the chat request's `think` field. `false` skips the
                thinking phase of reasoning models such as qwen3 (fast answers);
                null omits the field for servers or models that reject it.
            '';
        };

        debounceMs = mkOption {
            type = types.ints.unsigned;
            default = 700;
            description = "Idle time after the last keystroke before the model is asked.";
        };

        matchTimeout = mkOption {
            type = types.ints.positive;
            default = 20;
            description = ''
                Seconds a KRunner match request may wait for the first line of the
                answer before showing what has arrived so far. KRunner drops replies
                after 25 s.
            '';
        };

        runTimeout = mkOption {
            type = types.ints.positive;
            default = 90;
            description = "Seconds an activation waits for an unfinished answer before copying/opening what there is.";
        };

        minPromptLength = mkOption {
            type = types.ints.positive;
            default = 3;
            description = "Shortest question (characters after the trigger word) that is sent to the model.";
        };

        logPrompts = mkOption {
            type = types.bool;
            default = false;
            description = "Log questions and first answer lines to the journal (off: events and errors only).";
        };
    };

    config = mkIf cfg.enable {
        assertions = [
            {
                assertion = cfg.matchTimeout < 25;
                message = "services.krunner-ollama.matchTimeout must stay below KRunner's 25 s D-Bus timeout.";
            }
            {
                assertion = cfg.triggerWords != [ ]
                    && all (w: w != "" && !(hasInfix " " w) && !(hasInfix "," w)) cfg.triggerWords;
                message = "services.krunner-ollama.triggerWords needs at least one word, none containing spaces or commas.";
            }
        ];

        #-- KRunner plugin metadata + D-Bus activation file, system-wide
        #-- (/run/current-system/sw/share is on XDG_DATA_DIRS for both).
        environment.systemPackages = [ cfg.package ];

        systemd.user.services.krunner-ollama = {
            description = "KRunner runner for the local Ollama server";
            after = [ "graphical-session.target" ];
            partOf = [ "graphical-session.target" ];
            wantedBy = [ "graphical-session.target" ];

            environment = {
                KRUNNER_OLLAMA_URL = cfg.ollamaUrl;
                KRUNNER_OLLAMA_MODEL = cfg.model;
                KRUNNER_OLLAMA_WEBUI_URL = cfg.webuiUrl;
                KRUNNER_OLLAMA_TRIGGERS = concatStringsSep " " cfg.triggerWords;
                KRUNNER_OLLAMA_ON_ACTIVATE = cfg.onActivate;
                KRUNNER_OLLAMA_NUM_PREDICT = toString cfg.numPredict;
                KRUNNER_OLLAMA_THINK = if cfg.think == null then "" else boolToString cfg.think;
                KRUNNER_OLLAMA_DEBOUNCE_MS = toString cfg.debounceMs;
                KRUNNER_OLLAMA_MATCH_TIMEOUT = toString cfg.matchTimeout;
                KRUNNER_OLLAMA_RUN_TIMEOUT = toString cfg.runTimeout;
                KRUNNER_OLLAMA_MIN_PROMPT = toString cfg.minPromptLength;
                KRUNNER_OLLAMA_BUS_NAME = busName;
                KRUNNER_OLLAMA_LOG_PROMPTS = if cfg.logPrompts then "1" else "0";
            } // optionalAttrs (cfg.systemPrompt != null) {
                KRUNNER_OLLAMA_SYSTEM_PROMPT = cfg.systemPrompt;
            };

            serviceConfig = {
                Type = "dbus";
                BusName = busName;
                ExecStart = "${cfg.package}/bin/krunner-ollama";
                Restart = "on-failure";
                RestartSec = 5;

                #-- Sandbox. Everything here is enforced by an unprivileged
                #-- user manager (mount + user namespaces, seccomp); the
                #-- runtime dir is bound back in for the session bus and the
                #-- Wayland socket (wl-copy), which ProtectHome=tmpfs hides.
                NoNewPrivileges = true;
                PrivateTmp = true;
                PrivateDevices = true;
                ProtectSystem = "strict";
                ProtectHome = "tmpfs";
                BindReadOnlyPaths = [ "%t" ];
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
                MemoryDenyWriteExecute = true;
                RestrictAddressFamilies = [ "AF_UNIX" "AF_INET" "AF_INET6" "AF_NETLINK" ];
                SystemCallArchitectures = "native";
                SystemCallFilter = [ "@system-service" "~@privileged" "~@resources" ];
                CapabilityBoundingSet = [ "" ];
                UMask = "0077";
            };
        };
    };
}

# <> #
