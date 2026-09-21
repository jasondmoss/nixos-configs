# docker.nix
#
# Docker Engine for the Compose/DDEV/Lando based client projects (overlay2,
# weekly auto-prune) plus the buildx and compose CLI plugins.
{ pkgs, ... }: {
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

    environment.systemPackages = [
        pkgs.docker-buildx
        pkgs.docker-compose
    ];
}

# <> #
