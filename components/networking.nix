{ lib, ... }: {
	networking = {
        enableIPv6 = true;
        useDHCP = lib.mkDefault true;

        firewall = {
            enable = true;
            allowPing = true;
            checkReversePath = false;

            allowedTCPPorts = [ 22 80 443 1025 1143 33728 ];
            allowedUDPPorts = [];
        };

        networkmanager = {
            enable = true;
            insertNameservers = [ "127.0.0.1" ];
            wifi.powersave = false;
        };
    };
}

# <> #
