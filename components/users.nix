{ ... }: {
    users = {
#        groups = {
#            docker = {};
#        };

        users = {
            me = {
                isNormalUser = true;
                home = "/home/me";
                createHome = false;
                uid = 1000;
                group = "users";
                description = "Jason D. Moss";

                extraGroups = [
                    "33"
                    "audio"
                    "docker"
                    "mlocate"
                    "mysql"
                    "navidrome"
                    "networkmanager"
                    "power"
                    "video"
                    "wheel"
                    "wwwrun"
                ];
            };
        };
    };
}

# <> #
