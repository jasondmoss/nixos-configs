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

            allowedTCPPorts = [ 22 ];
            allowedUDPPorts = [];
        };

        networkmanager = {
            enable = true;
            dns = "none";
            wifi.powersave = false;
            plugins = with pkgs; [ networkmanager-openvpn ];

            ensureProfiles = {
                environmentFiles = [ "/var/lib/nm-secrets/wifi.env" ];
                profiles.Skynet = {
                    connection = {
                        id = "Skynet";
                        uuid = "441c1068-8fd5-479b-b342-41ed6be093de";
                        type = "wifi";
                        autoconnect = true;
                        autoconnect-priority = 10;
                    };
                    wifi = {
                        ssid = "Skynet";
                        mode = "infrastructure";
                    };
                    wifi-security = {
                        key-mgmt = "sae";
                        psk = "$WIFI_PSK";
                    };
                    ipv4.method = "auto";
                    ipv6.method = "auto";
                };
            };
        };
    };

    services = {
        coredns = {
            enable = true;
            config = ''
. {
    # Cloudflare and Google
    forward . 1.1.1.1 1.0.0.1 8.8.8.8 8.8.4.4
    cache
}

local {
    template IN A {
        answer "{{ .Name }} 0 IN A 127.0.0.1"
    }
}
            '';
        };

        openssh = {
            enable = true;

            settings = {
                PasswordAuthentication = false;
                PermitRootLogin = "no";
                KbdInteractiveAuthentication = false;
            };
        };
    };
}

# <> #
