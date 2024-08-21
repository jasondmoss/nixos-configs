{ config, options, pkgs, ... }:
{
    system.stateVersion = "24.05";

    imports = [
        ./hardware.nix
        ../../shared/hardware.nix

        ../../shared/configuration.nix

        ../../shared/applications.nix
        ./applications.nix

        # JetBrains PHPStorm Beta
        custom/jetbrains/default.nix
    ];

    time.timeZone = "America/Toronto";

    networking.hostName = "atreides";

    services.xserver.dpi = 162;

    systemd = {
        user.services.add_ssh_keys = {
            script = ''
ssh-add $HOME/.ssh/cyan_jason
ssh-add $HOME/.ssh/id_development_global
            '';
            wantedBy = [ "graphical-session.target" ];
            # wantedBy = [ "default.target" ];
        };
    };

    services = {
        displayManager = {
            ly = {
                settings = {
                    animation = "matrix";
                };
            };
        };
    };
}
