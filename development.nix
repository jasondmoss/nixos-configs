{ config, pkgs, ... }: {
    imports = [
        ./custom-packages/php
    ];

    virtualisation.docker = {
        enable = true;
        enableOnBoot = true;
        storageDriver = "overlay2";
#        package = pkgs.docker_25;
        package = pkgs.docker;

        autoPrune = {
            enable = true;
            dates = "weekly";
            flags = [ "--all" ];
        };
    };

    environment.systemPackages = [
        pkgs.docker-buildx
        pkgs.docker-compose
    ];
}

# <> #
