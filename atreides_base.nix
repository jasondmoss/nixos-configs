{ config, options, pkgs, ... }:
{
    system.stateVersion = "23.11";

    imports = [
        ./atreides_hardware.nix
        ./_configuration.nix
        ./_applications.nix

        # JetBrains PHPStorm Beta
        ./pkgs/jetbrains/default.nix
    ];

    time.timeZone = "America/Toronto";

    networking.hostName = "atreides";

    services.xserver.dpi = 162;

    systemd = {
        user.services.add_ssh_keys = {
            script = ''
ssh-add $HOME/.ssh/id_development_global
            '';
            wantedBy = [ "default.target" ];
        };
    };
}
