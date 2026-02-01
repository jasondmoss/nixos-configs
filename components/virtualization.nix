{ config, pkgs, ... }:
{
    virtualisation = {
        virtualbox.host.enable = true;

        docker = {
            enable = true;
            enableOnBoot = true;
            storageDriver = "overlay2";
            package = pkgs.docker_25;

            autoPrune = {
                enable = true;
                dates = "weekly";
                flags = [ "--all" ];
            };
        };
    };

    environment.systemPackages = [
        pkgs.docker-buildx
        pkgs.docker-compose
    ];
}
