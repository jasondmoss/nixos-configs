{ config, options, pkgs, ... }:
{
    system.stateVersion = "23.11";

    imports = [
        ./hardware.nix
        ../../shared/configuration.nix
        ../../shared/applications.nix

        # JetBrains PHPStorm Beta
        ../../custom/jetbrains/default.nix
    ];

    time.timeZone = "America/Toronto";

    networking.hostName = "icarus";

    services.xserver.dpi = 96;

    systemd = {
        user.services.add_ssh_keys = {
            script = ''
ssh-add $HOME/.ssh/cyan_jason
ssh-add $HOME/.ssh/id_development_global
            '';
            wantedBy = [ "default.target" ];
        };
    };
}
