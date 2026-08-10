# pcp-grafana.nix
#
# Grafana front-end for Performance Co-Pilot, wired to pmproxy (enabled in
# pcp.nix) with a Redis/pmseries backend for HISTORICAL metric queries.
#
# Data path:
#   pmlogger archives ──▶ pmproxy (series.discover) ──▶ Redis (pmseries index)
#                                    ▲                        │
#                        Grafana ───┘  (REST 44322)  ◀────────┘
#
# The grafana-pcp app plugin (packages/grafana-pcp, not in nixpkgs) is injected
# via declarativePlugins and provides these datasources (v6 renamed "Redis" to
# "Valkey" — Redis stays wire-compatible, so pmproxy + pkgs.redis still work):
#   - "PCP Valkey" (performancecopilot-valkey-datasource) → historical, pmproxy+Redis
#   - "PCP Vector" (performancecopilot-vector-datasource) → live/real-time, pmproxy
#
# Everything is loopback-only: Grafana on 127.0.0.1:3000, pmproxy on
# 127.0.0.1:44322, Redis on 127.0.0.1:6379. No firewall ports are opened.
#
# NOTE: The NixOS Grafana module can provision datasources but not *enable* an
# app plugin. The datasources below are provisioned by type and work directly.
# If the PCP app's own pages/dashboards don't appear, enable it once in the UI:
# Administration → Plugins → "Performance Co-Pilot" → Enable.
#
{ config, pkgs, lib, ... }:

let
  grafana-pcp = pkgs.callPackage ./packages/grafana-pcp { };
  pmproxyUrl = "http://127.0.0.1:44322";
in
{
  # ─── Redis backend for pmproxy's pmseries (historical time series) ────────
  services.redis.servers.pcp = {
    enable = true;
    bind = "127.0.0.1";
    port = 6379;
  };

  # ─── Grafana ──────────────────────────────────────────────────────────────
  services.grafana = {
    enable = true;

    declarativePlugins = [ grafana-pcp ];

    settings = {
      server = {
        http_addr = "127.0.0.1";
        http_port = 3000;
        domain = "localhost";
      };
      # Private/telemetry-off, matching the local-AI stack conventions.
      analytics = {
        reporting_enabled = false;
        check_for_updates = false;
        feedback_links_enabled = false;
      };
      "log" = { level = "info"; };
      # NixOS 26.05 dropped the built-in default secret_key (used to encrypt
      # secrets in Grafana's DB). This instance stores no credentials — the
      # provisioned datasources are auth-less — but the option is now mandatory.
      # Read it from a file that preStart generates on first boot, so no secret
      # is committed to this repo.
      security.secret_key = "$__file{/var/lib/grafana/secret_key}";
    };

    provision = {
      enable = true;
      datasources.settings = {
        apiVersion = 1;
        datasources = [
          {
            name = "PCP Valkey";
            type = "performancecopilot-valkey-datasource";
            access = "proxy";
            url = pmproxyUrl;
            isDefault = true;
            jsonData = { };
          }
          {
            name = "PCP Vector";
            type = "performancecopilot-vector-datasource";
            access = "proxy";
            url = pmproxyUrl;
            jsonData = { };
          }
        ];
      };
    };
  };

  # Grafana should come up after its data sources exist, and needs its
  # encryption key present before start. preStart runs as the grafana user with
  # /var/lib/grafana as its state dir, so it can create the key file itself.
  systemd.services.grafana = {
    after = [ "pmproxy.service" "redis-pcp.service" ];
    wants = [ "pmproxy.service" "redis-pcp.service" ];
    preStart = ''
      keyfile=/var/lib/grafana/secret_key
      if [ ! -s "$keyfile" ]; then
        ( umask 077; ${pkgs.openssl}/bin/openssl rand -base64 32 | tr -d '\n' > "$keyfile" )
      fi
    '';
  };
}

# <> #
