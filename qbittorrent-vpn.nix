{ pkgs, identity, ... }:

# Leak-proof qBittorrent.
#
# qBittorrent runs inside a dedicated network namespace ("qbit") whose ONLY
# route to the internet is a WireGuard tunnel (a ProtonVPN config). The physical
# NIC does not exist inside the namespace, so if the tunnel ever drops there is
# no fallback path — qBittorrent simply goes dark. This is a kill switch by
# construction, independent of the ProtonVPN GUI app.
#
# The private key lives at /etc/wireguard/qbit.conf (root:root 0600) and is NEVER
# placed in the nix store or git. Provision it once with:
#   sudo install -Dm600 ~/Desktop/wiregaurd-linux-US-MA-109.conf /etc/wireguard/qbit.conf

let
    ns      = "qbit";
    wgIface = "wg-qbit";
    wgConf  = "/etc/wireguard/qbit.conf";   # root:root 0600 — NOT in the nix store
    vpnAddr = "10.2.0.2/32";                 # [Interface] Address from the Proton config
    vpnDNS  = "10.2.0.1";                     # Proton DNS — only reachable inside the tunnel
    user    = identity.userHandle;

    # NAT-PMP port forwarding (the Proton config has it enabled). natpmpGateway is
    # Proton's gateway inside the tunnel; qbtWebPort is qBittorrent's Web UI port,
    # reached on the namespace's own loopback by the refresh loop below.
    natpmpGateway = "10.2.0.1";
    qbtWebPort    = "8080";

    # On-demand launcher: runs the qBittorrent GUI *inside* the VPN namespace.
    # The session vars ($WAYLAND_DISPLAY etc.) are expanded by the caller's shell
    # and baked into argv, so they survive the sudo -> runuser environment reset.
    # The Wayland/X sockets live under XDG_RUNTIME_DIR — a filesystem path that a
    # netns does not isolate — so the GUI connects to the compositor normally.
    qbittorrent-vpn = pkgs.writeShellScriptBin "qbittorrent-vpn" ''
        exec /run/wrappers/bin/sudo ${pkgs.iproute2}/bin/ip netns exec ${ns} \
            ${pkgs.util-linux}/bin/runuser -u ${user} -- \
            ${pkgs.coreutils}/bin/env \
                HOME="${identity.userHome}" \
                USER="${user}" \
                LOGNAME="${user}" \
                XDG_CACHE_HOME="${identity.userHome}/.cache" \
                XDG_CONFIG_HOME="${identity.userHome}/.config" \
                XDG_DATA_HOME="${identity.userHome}/.local/share" \
                XDG_STATE_HOME="${identity.userHome}/.local/state" \
                DISPLAY="''${DISPLAY:-}" \
                WAYLAND_DISPLAY="''${WAYLAND_DISPLAY:-}" \
                XDG_RUNTIME_DIR="''${XDG_RUNTIME_DIR:-}" \
                DBUS_SESSION_BUS_ADDRESS="''${DBUS_SESSION_BUS_ADDRESS:-}" \
                QT_QPA_PLATFORM="''${QT_QPA_PLATFORM:-wayland}" \
                ${pkgs.qbittorrent}/bin/qbittorrent "$@"
    '';

    qbittorrent-vpn-desktop = pkgs.makeDesktopItem {
        name        = "qbittorrent-vpn";
        desktopName = "qBittorrent (VPN)";
        comment     = "qBittorrent confined to the ProtonVPN network namespace";
        exec        = "${qbittorrent-vpn}/bin/qbittorrent-vpn %U";
        icon        = "qbittorrent";
        categories  = [ "Network" "FileTransfer" "P2P" ];
        terminal    = false;
    };
in
{
    # Resolver used *inside* the namespace. `ip netns exec` bind-mounts this over
    # /etc/resolv.conf; the system CoreDNS at 127.0.0.1 is not present in the ns.
    environment.etc."netns/${ns}/resolv.conf".text = "nameserver ${vpnDNS}\n";

    environment.systemPackages = [
        qbittorrent-vpn
        qbittorrent-vpn-desktop
        pkgs.wireguard-tools        # `wg`, `wg-quick` — handy for `sudo ip netns exec qbit wg show`
        pkgs.libnatpmp              # `natpmpc` — manual port-forward checks / used by natpmp-qbit
    ];

    # Let the desktop user enter the namespace without a password prompt.
    security.sudo.extraRules = [{
        users = [ user ];
        commands = [{
            command = "${pkgs.iproute2}/bin/ip netns exec ${ns} *";
            options = [ "NOPASSWD" ];
        }];
    }];

    systemd.services.wg-qbit = {
        description = "WireGuard VPN network namespace for qBittorrent";
        after       = [ "network-online.target" ];
        wants       = [ "network-online.target" ];
        wantedBy    = [ "multi-user.target" ];
        path        = [ pkgs.iproute2 pkgs.wireguard-tools ];

        serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
        };

        script = ''
            set -e

            # Clear any stale state from a previous run or crash.
            ip -n ${ns} link del ${wgIface} 2>/dev/null || true
            ip link del ${wgIface} 2>/dev/null || true

            # Namespace (idempotent) + loopback.
            ip netns add ${ns} 2>/dev/null || true
            ip -n ${ns} link set lo up

            # Create the wg interface in the ROOT namespace first so its encrypted
            # UDP socket egresses via the physical NIC, THEN move the interface into
            # the namespace. The transport socket stays in the namespace where the
            # interface was created — this is what lets the tunnel reach its endpoint
            # while everything else inside "qbit" is fully isolated.
            ip link add ${wgIface} type wireguard
            ip link set ${wgIface} netns ${ns}

            # Apply the Proton config (private key, peer, endpoint). `wg-quick strip`
            # drops the Address/DNS/MTU lines that `wg setconf` does not understand.
            ip netns exec ${ns} wg setconf ${wgIface} <(wg-quick strip ${wgConf})

            # Address, bring up, and route ALL traffic in the namespace via the tunnel.
            ip -n ${ns} addr add ${vpnAddr} dev ${wgIface}
            ip -n ${ns} link set ${wgIface} up
            ip -n ${ns} route add default dev ${wgIface}
        '';

        preStop = ''
            ${pkgs.iproute2}/bin/ip -n ${ns} link del ${wgIface} 2>/dev/null || true
            ${pkgs.iproute2}/bin/ip netns del ${ns} 2>/dev/null || true
        '';
    };

    # Keep Proton's NAT-PMP port mapping alive and feed the assigned public port
    # into qBittorrent. Runs *inside* the qbit namespace, so it talks to the tunnel
    # gateway and to qBittorrent's Web UI on the namespace's own loopback. Proton
    # expires the mapping after ~60s, hence the 45s refresh loop. The current port
    # is also written to /run/qbit-forwarded-port for visibility (`cat` it anytime).
    systemd.services.natpmp-qbit = {
        description = "Proton NAT-PMP port forwarding for qBittorrent";
        after    = [ "wg-qbit.service" ];
        bindsTo  = [ "wg-qbit.service" ];   # tear down / restart together with the tunnel
        wantedBy = [ "multi-user.target" ];
        path     = [ pkgs.libnatpmp pkgs.curl pkgs.gnused pkgs.coreutils ];

        serviceConfig = {
            NetworkNamespacePath = "/run/netns/${ns}";   # join the qbit namespace
            Restart = "always";
            RestartSec = "10s";
        };

        script = ''
            set -u
            last_port=0
            while true; do
                # Refresh TCP + UDP leases; "1 0" lets the gateway choose the public
                # port (Proton returns the same one for both protocols).
                out=$(natpmpc -a 1 0 tcp 60 -g ${natpmpGateway} 2>/dev/null)
                natpmpc -a 1 0 udp 60 -g ${natpmpGateway} >/dev/null 2>&1
                port=$(printf '%s\n' "$out" | sed -n 's/.*Mapped public port \([0-9]\+\).*/\1/p' | head -n1)

                if [ -n "$port" ]; then
                    printf '%s\n' "$port" > /run/qbit-forwarded-port
                    if [ "$port" != "$last_port" ]; then
                        # Push the new port to qBittorrent IF its Web UI is reachable.
                        # Requires Web UI enabled with "Bypass authentication for
                        # localhost" so 127.0.0.1 needs no login. Harmless no-op when
                        # qBittorrent is not running.
                        if curl -fsS --max-time 5 "http://127.0.0.1:${qbtWebPort}/api/v2/app/version" >/dev/null 2>&1; then
                            if curl -fsS --max-time 5 \
                                "http://127.0.0.1:${qbtWebPort}/api/v2/app/setPreferences" \
                                --data-urlencode 'json={"listen_port":'"$port"',"upnp":false,"random_port":false}' >/dev/null 2>&1; then
                                last_port="$port"
                            fi
                        fi
                    fi
                fi
                sleep 45
            done
        '';
    };
}

# <> #
