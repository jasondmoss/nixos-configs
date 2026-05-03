{ lib, pkgs, ... }: {
    networking = {
        enableIPv6 = true;
        useDHCP = lib.mkDefault true;
        nftables.enable = false;

        firewall = {
            enable = true;
            allowPing = true;
            checkReversePath = "loose";
            logRefusedConnections = true;

            allowedTCPPorts = [ 22 80 443 ];
            allowedUDPPorts = [];
        };

        networkmanager = {
            enable = true;
            insertNameservers = [ "127.0.0.1" ];
            wifi.powersave = false;
            plugins = with pkgs; [ networkmanager-openvpn ];
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
