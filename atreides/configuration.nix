{ config, options, pkgs, ... }:
let
    theme = import ../shared/theme.nix;
in {

    system.stateVersion = "23.11";


    imports = [
        ./hardware.nix
        ./webserver.nix
        ../shared/applications.nix
        # QT6 Development
        #../shared/pkgs/qt-6/default.nix
        # JetBrains PHPStorm Beta
        ../shared/pkgs/jetbrains/default.nix
    ];


    i18n = {
        defaultLocale = "en_CA.utf8";

        inputMethod = {
            enabled = "ibus";
            ibus.engines = with pkgs.ibus-engines; [ table table-others ];
        };
    };


    time.timeZone = "America/Toronto";


    nix = {
        package = pkgs.nixUnstable;

        settings = {
            trusted-users = [ "root" "@wheel" ];
            experimental-features = "nix-command flakes";
            auto-optimise-store = true;
            max-jobs = "auto";
        };
    };


    documentation = {
        enable = true;
        man.enable = true;
        dev.enable = true;
    };


    fonts = {
        fontconfig.enable = true;
        fontDir.enable = true;

        packages = with pkgs; [
            corefonts
            fira-code-symbols
            freefont_ttf
            jetbrains-mono
            nerdfonts
            overpass
            powerline-fonts
            terminus_font
            unifont
        ];
    };


    console = {
        earlySetup = true;
        font = "Lat2-Terminus16";
        keyMap = "us";
        colors = theme.colors16;
    };


    services = {
        gnome = {
            at-spi2-core.enable = true;
        };

        gvfs.enable = true;

        locate = {
            enable = true;
            locate = pkgs.mlocate;
            interval = "hourly";
            localuser = null;
        };

        openssh = {
            enable = true;

            settings = {
                PasswordAuthentication = true;
                PermitRootLogin = "no";
                KbdInteractiveAuthentication = true;
            };
        };

        pcscd.enable = true;

        pipewire = {
            enable = true;

            alsa.enable = true;
            alsa.support32Bit = true;
            pulse.enable = true;
        };

        xserver = {
            enable = true;
            videoDrivers = [ "nvidia" ];
            layout = "us";
            xkbVariant = "";
            dpi = 162;

            displayManager = {
                gdm.enable = false;

                sddm = {
                    enable = true;
                    enableHidpi = true;

                    theme = "${(pkgs.fetchFromGitLab {
                        owner = "Matt.Jolly";
                        repo = "sddm-eucalyptus-drop";
                        rev = "433ca77c1dd73f227a0d28d378e36c8f61aff33d";
                        sha256 = "sha256-lIDPvXtqUdnLaGFtsH6KT89Kn6VPk7xItUiU3Uzf2AQ=";
                    })}";
                };

                defaultSession = "plasma";
            };

            desktopManager = {
                gnome.enable = false;

                plasma5 = {
                    enable = true;
                    useQtScaling = true;
                };
            };
        };
    };


    xdg.portal.enable = true;
    sound.enable = true;


    programs = {
        bash.enableCompletion = true;
        dconf.enable = true;
        mtr.enable = true;

        ssh = {
            startAgent = true;
            askPassword = pkgs.lib.mkForce "${pkgs.ksshaskpass.out}/bin/ksshaskpass";
        };

        steam = {
            enable = true;

            remotePlay.openFirewall = true;
            dedicatedServer.openFirewall = true;
        };

        sway.enable = true;
        xwayland.enable = false;
    };


    security = {
        rtkit.enable = true;

        pam.services = {
            kwallet = {
                name = "kwallet";
                enableKwallet = true;
            };
        };

        sudo = {
            enable = true;
            wheelNeedsPassword = false;
            extraConfig = ''
                Defaults:me !authenticate
            '';
        };
    };


    systemd.user.services.add_ssh_keys = {
        script = ''
            ssh-add $HOME/.ssh/id_development_global
        '';
        wantedBy = [ "multi-user.target" ];
    };


    users.users = {
        me = {
            isNormalUser = true;
            home = "/home/me";
            createHome = false;
            uid = 1000;
            group = "users";
            description = "Jason D. Moss";

            extraGroups = [
                "wheel" "audio" "video" "power" "wwwrun" "networkmanager" "mysql" "mlocate"
            ];
        };
    };

}
