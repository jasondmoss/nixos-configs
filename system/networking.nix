{ lib, pkgs, ... }: {
    networking = {
        enableIPv6 = false;
        useDHCP = lib.mkDefault true;
        nftables.enable = false;

        nameservers = [ "127.0.0.1" ];

        firewall = {
            enable = true;
            allowPing = true;
            checkReversePath = "loose";
            logRefusedConnections = true;

            # Nothing is open to the world. SSH is admitted from the LAN only
            # (extraCommands below); KDE Connect's 1714–1764 TCP/UDP range is
            # opened by programs.kdeconnect itself (programs.nix), Steam Remote
            # Play by programs.steam.
            allowedTCPPorts = [];
            allowedUDPPorts = [];

            # SSH from the local subnet only. services.openssh.openFirewall is
            # off (below), so this rule is the only way in. Widen the source
            # range if you ever need to reach the box from another network.
            extraCommands = ''
iptables -A nixos-fw -p tcp --dport 22 -s 192.168.100.0/24 -j nixos-fw-accept
            '';
        };

        networkmanager = {
            enable = true;
            dns = "none";
            wifi.powersave = false;
            plugins = with pkgs; [ networkmanager-openvpn ];

            # The generated keyfile is passed through envsubst with the
            # variables from environmentFiles, so every `$VAR` below is filled
            # in at activation and never appears in this (public) repo. The
            # file must define both WIFI_SSID and WIFI_PSK (root:root 0600):
            #   printf 'WIFI_SSID=…\nWIFI_PSK=…\n' | sudo tee /var/lib/nm-secrets/wifi.env
            ensureProfiles = {
                environmentFiles = [ "/var/lib/nm-secrets/wifi.env" ];
                profiles.home = {
                    connection = {
                        id = "$WIFI_SSID";
                        # Keep this uuid stable: NetworkManager identifies the
                        # connection by it, so renaming the profile above does
                        # not create a second one.
                        uuid = "441c1068-8fd5-479b-b342-41ed6be093de";
                        type = "wifi";
                        autoconnect = true;
                        autoconnect-priority = 10;
                    };
                    wifi = {
                        ssid = "$WIFI_SSID";
                        mode = "infrastructure";
                    };
                    wifi-security = {
                        key-mgmt = "sae";
                        psk = "$WIFI_PSK";
                    };
                    ipv4.method = "auto";
                    # IPv6 is off system-wide (enableIPv6 = false); stop NM from
                    # running a DHCPv6/RA client on the link anyway.
                    ipv6.method = "disabled";
                };
            };
        };
    };

    services = {
        coredns = {
            enable = true;
            config = ''
. {
    # Loopback only — never an open resolver on the LAN/docker bridges.
    bind 127.0.0.1

    # DNS over TLS to Cloudflare: query names are encrypted on the wire, so
    # neither the LAN nor the ISP sees what is being resolved. Verification
    # is by IP + SNI, so no bootstrap lookup is needed.
    forward . tls://1.1.1.1 tls://1.0.0.1 {
        tls_servername cloudflare-dns.com
        health_check 10s
    }
    cache
}

local {
    bind 127.0.0.1
    template IN A {
        answer "{{ .Name }} 0 IN A 127.0.0.1"
    }
}
            '';
        };

        openssh = {
            enable = true;
            # Port 22 is opened for the LAN only, in networking.firewall above.
            openFirewall = false;

            settings = {
                PasswordAuthentication = false;
                PermitRootLogin = "no";
                KbdInteractiveAuthentication = false;
                AllowUsers = [ "me" ];
            };
        };
    };
}

# <> #
