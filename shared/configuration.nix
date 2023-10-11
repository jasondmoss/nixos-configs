{ config, options, pkgs, ... }:
let
    theme = import ./theme.nix;
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

            displayManager = {
                gdm.enable = false;

                sddm = {
                    enable = true;
                    enableHidpi = true;

                    # wayland = {
                    #     enable = true;
                    # };

                    # theme = "${(pkgs.fetchFromGitLab {
                    #     owner = "Matt.Jolly";
                    #     repo = "sddm-eucalyptus-drop";
                    #     rev = "433ca77c1dd73f227a0d28d378e36c8f61aff33d";
                    #     sha256 = "sha256-lIDPvXtqUdnLaGFtsH6KT89Kn6VPk7xItUiU3Uzf2AQ=";
                    # })}";

                    settings = {
                        Wayland.SessionDir = "${pkgs.plasma5Packages.plasma-workspace}/share/wayland-sessions";
                    };
                };

                defaultSession = "plasma";
                # defaultSession = "plasmawayland";
            };

            desktopManager = {
                gnome.enable = false;

                plasma5 = {
                    enable = true;
                    useQtScaling = true;
                };
            };
        };

        httpd = {
            enable = false;
            adminAddr = "me@localhost";
            user = "me";
            group = "users";
            extraModules = [ "http2" ];
            enablePHP = true;

            phpPackage = pkgs.php82.buildEnv {
                extensions = ({ enabled, all }: enabled);
                extraConfig = "memory_limit = 1024M";
            };

            phpOptions = ''
                display_errors = On
                display_startup_errors = On
                allow_url_fopen = on
                post_max_size = 200M
                upload_max_filesize = 1024M
                max_execution_time = 6000
                max_input_time = 3000
                mbstring.http_input = pass
                mbstring.http_output = pass
                mbstring.internal_encoding = pass
                memory_limit = 1024M;
                allow_url_include = On;
            '';

            #virtualHosts = {
               #"jdmlabs-drupal" = {
               #    documentRoot = "/srv/jdmlabs-drupal/web";
               #    servedDirs = [{
               #        urlPath = "/srv/jdmlabs-drupal/web";
               #        dir = "/srv/jdmlabs-drupal/web";
               #    }];
               #    serverAliases = [ "jdmlabs-drupal.test" "jdmlabs-drupal-redirect.test" ];
               #    extraConfig = ''
               #        <Directory "/srv/jdmlabs-drupal/web">
               #            Options +Indexes +ExecCGI +FollowSymlinks -SymLinksIfOwnerMatch
               #            RewriteEngine On
               #            DirectoryIndex index.html index.html.var index.php
               #            Require all granted
               #            AllowOverride All
               #        </Directory>
               #    '';
               #};

               #"jdmlabs-laravel" = {
               #    documentRoot = "/srv/jdmlabs-laravel/public";
               #    servedDirs = [{
               #        urlPath = "/srv/jdmlabs-laravel/public";
               #        dir = "/srv/jdmlabs-laravel/public";
               #    }];
               #    serverAliases = [ "jdmlabs-laravel.test" "jdmlabs-laravel-redirect.test" ];
               #    extraConfig = ''
               #        <Directory "/srv/jdmlabs-laravel/public">
               #            Options +Indexes +ExecCGI +FollowSymlinks -SymLinksIfOwnerMatch
               #            RewriteEngine On
               #            DirectoryIndex index.html index.html.var index.php
               #            Require all granted
               #            AllowOverride All
               #        </Directory>
               #    '';
               #};
            #};
        };

        mysql = {
            enable = false;
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

    networking = {
        enableIPv6 = true;

        ## Switched to DDEV
        #extraHosts = ''
        #    127.0.0.1 adminer.test
        #    127.0.0.1 jdmlabs-craft.test
        #    127.0.0.1 jdmlabs-drupal.test
        #    127.0.0.1 jdmlabs-laravel.test
        #    127.0.0.1 canoe-north.test
        #    127.0.0.1 hay-river.test
        #    # 127.0.0.1 travel-media.test
        #    # 127.0.0.1 travel-trade.test
        #    # 127.0.0.1 spectacularnwt.test
        #    127.0.0.1 localhost
        #    127.0.0.1 localhost.localdomain
        #'';

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

        pam.services = {
            kwallet = {
                name = "kwallet";
                enableKwallet = true;
            };

            # swaylock.text = ''
            #     auth include login
            # '';
        };

        sudo = {
            enable = true;
            wheelNeedsPassword = false;
            extraConfig = ''
                Defaults:me !authenticate
            '';
        };

        auditd.enable = true;
        #audit = {
        #    enable = true;
        #    rules = [
        #        "-a exit,always -F arch=x86_64-linux -S execve"
        #    ];
        #};
    };

    i18n = {
        defaultLocale = "en_CA.utf8";

        inputMethod = {
            enabled = "ibus";
            ibus.engines = with pkgs.ibus-engines; [ table table-others ];
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

        sway = {
             enable = true;
             wrapperFeatures.gtk = true;
        };

        xwayland.enable = true;
    };

    xdg.portal.enable = true;

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
