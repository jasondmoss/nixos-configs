{ config, options, pkgs, ... }:
let
    theme = import ./theme.nix;

    localAddress = "127.0.0.1";
in {
    nix = {
        package = pkgs.nixVersions.latest;

        settings = {
            trusted-users = [ "root" "@wheel" ];
            experimental-features = "nix-command flakes";
            auto-optimise-store = true;
            max-jobs = "auto";
        };
    };

    i18n = {
        defaultLocale = "en_CA.utf8";

        inputMethod = {
            enabled = "ibus";
            ibus.engines = with pkgs.ibus-engines; [
                table table-others
            ];
        };
    };

    fonts = {
        fontconfig.enable = true;
        fontDir.enable = true;

        packages = with pkgs; [
            corefonts
            freefont_ttf
            jetbrains-mono
            nerdfonts
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
        coredns = {
            enable = true;
            config = ''
. {
    # Cloudflare and Google
    forward . 1.1.1.1 1.0.0.1 8.8.8.8 8.8.4.4
    cache
}

local {
    template IN A {
        answer "{{ .Name }} 0 IN A 127.0.0.1"
    }
}
            '';
        };

        gnome = {
            at-spi2-core.enable = true;
        };

        dbus.enable = true;
        gvfs.enable = true;
        udev.enable = true;
        devmon.enable = true;
        sysstat.enable = true;

        locate = {
            enable = true;
            package = pkgs.mlocate;
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

        pipewire = {
            enable = true;
            alsa.enable = true;
            alsa.support32Bit = true;
            pulse.enable = true;
        };

        displayManager = {
            sddm = {
                enable = true;
                enableHidpi = true;

                #wayland.enable = true;
                #settings.Wayland.SessionDir = "${pkgs.kdePackages.plasma-workspace}/share/wayland-sessions";
            };

            defaultSession = "plasmax11";
            #defaultSession = "plasma";
        };

        desktopManager = {
            plasma6 = {
               enable = true;
               enableQt5Integration = false;
            };
        };

        xserver = {
            enable = true;
            videoDrivers = [ "nvidia" ];

            xkb = {
                layout = "us";
                variant = "";
            };
        };

        httpd = {
            enable = true;
            adminAddr = "me@localhost";
            user = "me";
            group = "users";
            extraModules = [ "http2" ];
            enablePHP = true;

            phpPackage = pkgs.php82.buildEnv {
                extensions = ({ enabled, all }: enabled);
                extraConfig = "memory_limit = 2048M";
            };

            phpOptions = ''
display_errors = On
display_startup_errors = On
allow_url_fopen = on
memory_limit = 2048M
post_max_size = 2048M
upload_max_filesize = 2048M
max_execution_time = 10000
max_input_time = 3000
mbstring.http_input = pass
mbstring.http_output = pass
mbstring.internal_encoding = pass
memory_limit = 2048M;
allow_url_include = On;
session.cookie_samesite = "Strict"
            '';
        };

        mysql = {
            enable = true;
            package = pkgs.mariadb;

            settings = {
                mysqld = {
                    transaction-isolation = "READ-COMMITTED";
                };
            };

            ensureUsers = [
                {
                    name = "me";
                    ensurePermissions = {
                        "*.*" = "ALL PRIVILEGES";
                    };
                }
            ];
        };
    };

    programs = {
        bash.completion.enable = true;
        dconf.enable = true;
        kdeconnect.enable = true;
        mtr.enable = true;
        xwayland.enable = true;

        ssh = {
            startAgent = true;
            askPassword = pkgs.lib.mkForce "${pkgs.ksshaskpass.out}/bin/ksshaskpass";
        };

        steam = {
            enable = true;
            remotePlay.openFirewall = true;
            dedicatedServer.openFirewall = true;
        };

        git = {
            enable = true;

            config = {
                user.name = "jasondmoss";
                user.email = "jason@jdmlabs.com";
                credential.helper = "cache --timeout=86400";
            };

            lfs.enable = true;
        };

        neovim = {
            enable = true;
            defaultEditor = true;
            viAlias = true;
            vimAlias = true;
            withNodeJs = true;
            withPython3 = true;
        };
    };

    xdg.portal = {
        enable = true;

        config = {
            common.default = "*";
        };
    };

    networking = {
        enableIPv6 = true;

        firewall = {
            allowPing = true;
            allowedTCPPorts = [ 22 80 443 1025 1143 33728 ];
        };

        networkmanager = {
            enable = true;
            insertNameservers = [ "127.0.0.1" ];
        };
    };

    security = {
        rtkit.enable = true;
        polkit.enable = true;

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

    sound.enable = true;

    documentation = {
        enable = true;
        man.enable = true;
        dev.enable = true;
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
                "audio"
                "docker"
                "mlocate"
                "mysql"
                "networkmanager"
                "power"
                "video"
                "wheel"
                "wwwrun"
            ];
        };
    };

    systemd = {
        extraConfig = "DefaultTimeoutStopSec=10s";
    };
}
