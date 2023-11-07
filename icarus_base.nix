{ config, options, pkgs, ... }:
{
    system.stateVersion = "23.11";

    imports = [
        ./icarus_hardware.nix
        ./_configuration.nix
        ./_applications.nix

        # JetBrains PHPStorm Beta
        ./pkgs/jetbrains/default.nix
    ];

    time.timeZone = "America/Toronto";

    networking.hostName = "icarus";

    services.xserver.dpi = 96;

    systemd = {
        user.services.add_ssh_keys = {
            script = ''
ssh-add $HOME/.ssh/icarus_development
            '';
            wantedBy = [ "default.target" ];
        };
    };
}
