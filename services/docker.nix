# docker.nix
#
# Docker Engine for the Compose/DDEV/Lando based client projects (overlay2,
# weekly auto-prune) plus the buildx and compose CLI plugins, and a watcher
# that clears the raw-table rules Docker leaks when a network is removed.
{ config, pkgs, ... }:
let
    # Docker 29 guards every container with a port published on 127.0.0.1 by a
    # raw PREROUTING rule, `-d <container-ip> ! -i br-<network> -j DROP`, and
    # does not delete it when the network goes away. The next network to hand
    # out that IP then has all traffic to it from its own bridge dropped: on
    # 2026-10-26 this cut a Lando appserver off from its database and redis
    # (every Lando URL check timed out, `lando pull` hung). The host itself is
    # unaffected, because locally generated packets skip PREROUTING.
    #
    # Only rules whose bridge no longer exists are removed, so the protection
    # stays in place for every live network. Runs once when Docker starts,
    # then after each network removal (Lando poweroff/destroy, autoPrune).
    dockerRawRulesGc = pkgs.writeShellApplication {
        name = "docker-raw-rules-gc";
        runtimeInputs = [ pkgs.iptables pkgs.gnugrep config.virtualisation.docker.package ];
        text = ''
gc() {
    iptables -w -t raw -S PREROUTING \
        | { grep -E '^-A PREROUTING -d [0-9.]+/32 ! -i br-[0-9a-f]+ -j DROP$' || true; } \
        | while read -r rule; do
            bridge=$(grep -oE 'br-[0-9a-f]+' <<<"$rule")
            [ -e "/sys/class/net/$bridge" ] && continue
            read -ra args <<<"''${rule/#-A/-D}"
            if iptables -w -t raw "''${args[@]}"; then
                echo "removed stale rule: $rule"
            else
                echo "could not remove: $rule" >&2
            fi
        done
}

gc
# Give Docker a moment to remove the bridge interface before checking.
docker events --filter type=network --filter event=destroy --format '{{.Actor.ID}}' \
    | while read -r _; do sleep 2; gc; done
        '';
    };
in {
    virtualisation.docker = {
        enable = true;
        enableOnBoot = true;
        storageDriver = "overlay2";
        package = pkgs.docker;
#        package = pkgs.docker_25;

        daemon.settings = {
            default-ulimits.nofile = {
                Name = "nofile";
                Soft = 524288;
                Hard = 524288;
            };
        };

        autoPrune = {
            enable = true;
            dates = "weekly";
            flags = [ "--all" ];
        };
    };

    systemd.services.docker.environment.DOCKER_MIN_API_VERSION = "1.24";

    systemd.services.docker-raw-rules-gc = {
        description = "Remove Docker raw-table DROP rules left behind by deleted networks";
        after = [ "docker.service" ];
        bindsTo = [ "docker.service" ];
        # multi-user.target so a rebuild starts it; docker.service so it comes
        # back whenever Docker is restarted (bindsTo stops it with Docker).
        wantedBy = [ "multi-user.target" "docker.service" ];
        serviceConfig = {
            ExecStart = "${dockerRawRulesGc}/bin/docker-raw-rules-gc";
            Restart = "always";
            RestartSec = 5;
        };
    };

    environment.systemPackages = [
        pkgs.docker-buildx
        pkgs.docker-compose
    ];
}

# <> #
