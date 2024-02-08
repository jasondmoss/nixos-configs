{ config, options, pkgs, ... }:
let
    theme = import ./_theme.nix;
in {
    nix = {
        package = pkgs.nixUnstable;

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

        # elasticsearch = {
        #     enable = true;
        #     listenAddress = "9200";
        # };

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

        # pcscd.enable = true;

        pipewire = {
            enable = true;
            alsa.enable = true;
            alsa.support32Bit = true;
            pulse.enable = true;
        };

        xserver = {
            enable = true;
            videoDrivers = [ "nvidia" ];
            xkb = {
                layout = "us";
                variant = "";
            };

            displayManager = {
                sddm = {
                    enable = true;
                    enableHidpi = true;

                    # wayland.enable = true;
                    # settings.Wayland.SessionDir = "${pkgs.plasma5Packages.plasma-workspace}/share/wayland-sessions";
                };

                 defaultSession = "plasma";
                 # defaultSession = "plasmawayland";
            };

            desktopManager = {
                plasma5 = {
                    enable = true;
                    useQtScaling = true;
                };
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

        #sway = {
        #     enable = true;
        #     #wrapperFeatures.gtk = true;
        #};

        #wayfire = {
        #    enable = true;
        #    plugins = with pkgs.wayfirePlugins; [
        #        wcm
        #        wf-shell
        #        wayfire-plugins-extra
        #    ];
        #};

        xwayland.enable = true;
    };

    xdg.portal = {
        enable = true;

        config = {
            common.default = "*";
        };
    };

    networking = {
        enableIPv6 = true;

        extraHosts = ''
            23.128.160.24 cyanserver.ca
            23.128.160.24 web-a7g7.hostresolver.net
        '';

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

            #swaylock.text = ''
            #    auth include login
            #'';
        };

        sudo = {
            enable = true;
            wheelNeedsPassword = false;
            extraConfig = ''
                Defaults:me !authenticate
            '';
        };

        # auditd.enable = true;
        # audit = {
        #     enable = true;
        #     rules = [
        #         "-a exit,always -F arch=x86_64-linux -S execve"
        #     ];
        # };
    };

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
