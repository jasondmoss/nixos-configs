{ config, lib, pkgs, ... }:
let
    theme = import ./components/theme.nix;
in {

    system.rebuild.enableNg  = true;

    nix = {
        package = pkgs.nixVersions.latest;

        settings = {
            trusted-users = [ "root" "me" "@wheel" ];
            allowed-users = [ "root" "me" "@wheel" ];
            experimental-features = "nix-command flakes";
            auto-optimise-store = true;
            max-jobs = "auto";
        };
    };

    i18n.defaultLocale = "en_CA.UTF-8";

#    fonts = {
#        fontDir = {
#            enable = true;
#            decompressFonts = config.programs.xwayland.enable;
#        };
#
#        fontconfig = {
#            enable = true;
#            antialias = true;
#
#            hinting = {
#                enable = true;
#                style = "slight";
#            };
#        };
#
#        packages = with pkgs; [
#            dotcolon-fonts
#            freefont_ttf
#            google-fonts
#            jetbrains-mono
#            liberation_ttf
#            paratype-pt-sans
#            paratype-pt-mono
#            profont
#            terminus_font
#            unifont
#        ];
#    };

    console = {
        earlySetup = true;
        #font = null;
        keyMap = "us";
        colors = theme.colors16;
    };

#    xdg.portal = {
#        enable = true;
#        xdgOpenUsePortal = true;
#        config = {
#            kde.default = [ "kde" "gtk" "gnome" ];
#            kde."org.freedesktop.portal.FileChooser" = [ "kde" ];
#            kde."org.freedesktop.portal.OpenURI" = [ "kde" ];
#        };
#        extraPortals = with pkgs; [
#            xdg-desktop-portal
#            xdg-desktop-portal-termfilechooser
#            kdePackages.xdg-desktop-portal-kde
#        ];
#    };

#    networking = {
#        enableIPv6 = true;
#        useDHCP = lib.mkDefault true;
#
#        firewall = {
#            enable = true;
#            allowPing = true;
#            checkReversePath = false;
#
#            allowedTCPPorts = [ 22 80 443 1025 1143 33728 ];
#            allowedUDPPorts = [];
#        };
#
#        networkmanager = {
#            enable = true;
#            insertNameservers = [ "127.0.0.1" ];
#            wifi.powersave = false;
#        };
#    };

#    security = {
#        rtkit.enable = true;
#        polkit.enable = true;
#
#        pam = {
#            sshAgentAuth = {
#                enable = true;
#            };
#
#            services = {
#                kwallet = {
#                    kwallet.enable = true;
#                };
#
#                ly = {
#                    kwallet.enable = true;
#                };
#            };
#        };
#
#        sudo = {
#            enable = true;
#            wheelNeedsPassword = false;
#            extraConfig = ''
#Defaults:me !authenticate
## Keep SSH_AUTH_SOCK so that pam_ssh_agent_auth.so can do its magic.
#Defaults env_keep+=SSH_AUTH_SOCK
#            '';
#        };
#    };

    documentation = {
        enable = true;
        man.enable = true;
        dev.enable = true;
    };

#    users.users = {
#        me = {
#            isNormalUser = true;
#            home = "/home/me";
#            createHome = false;
#            uid = 1000;
#            group = "users";
#            description = "Jason D. Moss";
#
#            extraGroups = [
#                "33"
#                "audio"
#                "docker"
#                "mlocate"
#                "mysql"
#                "navidrome"
#                "networkmanager"
#                "power"
#                "video"
#                "wheel"
#                "wwwrun"
#            ];
#        };
#    };

}
