{ config, options, lib, pkgs, ... }:
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
    };

    fonts = {
        fontDir = {
            enable = true;
            decompressFonts = config.programs.xwayland.enable;
        };

        fontconfig = {
            enable = true;
            antialias = true;
            hinting = {
                enable = true;
                style = "medium";
            };
        };

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
            ly = {
                enable = true;

                settings = {
                    clear_password = true;
                    clock = "%c";
                    animation = "matrix";
                    animation_timeout_sec = "20";
                    waylandsessions = "${pkgs.kdePackages.plasma-workspace}/share/wayland-sessions";
                };
            };

            defaultSession = "plasma";
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

            screenSection = ''
Option "metamodes" "nvidia-auto-select +0+0 {ForceFullCompositionPipeline=On}"
Option "AllowIndirectGLXProtocol" "off"
Option "TripleBuffer" "on"
            '';

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

            phpPackage = pkgs.php84.buildEnv {
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

        ollama = {
            enable = true;
            acceleration = "cuda";
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
            "ly" = {
                enableKwallet = true;
            };

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

    environment = {
        variables = {
            VDPAU_DRIVER = "va_gl";
            LIBVA_DRIVER_NAME = "nvidia";
            GBM_BACKEND = "nvidia-drm";
            __GLX_VENDOR_LIBRARY_NAME = "nvidia";
            WLR_NO_HARDWARE_CURSORS = "1";
            MOZ_DISABLE_RDD_SANDBOX = "1";
            NVD_BACKEND = "direct";
            EGL_PLATFORM = "wayland";
            __GL_GSYNC_ALLOWED = "1";
            WLR_DRM_NO_ATOMIC = "1";
            _JAVA_AWT_WM_NONREPARENTING = "1";
            SDL_VIDEODRIVER = "wayland";
            MOZ_ENABLE_WAYLAND = "1";
            NIXOS_OZONE_WL = "1";

            GST_PLUGIN_SYSTEM_PATH_1_0 = lib.makeSearchPathOutput "lib" "lib/gstreamer-1.0" [
                pkgs.gst_all_1.gst-editing-services
                pkgs.gst_all_1.gst-libav
                pkgs.gst_all_1.gst-plugins-bad
                pkgs.gst_all_1.gst-plugins-base
                pkgs.gst_all_1.gst-plugins-good
                pkgs.gst_all_1.gst-plugins-ugly
                pkgs.gst_all_1.gstreamer
            ];
        };

        sessionVariables = {
            XDG_MENU_PREFIX = "kde-";

            XCURSOR_THEME = "ComixCursors";
            DEFAULT_BROWSER = "/run/current-system/sw/bin/firefox-nightly";

            QT_QPA_PLATFORMTHEME = "qt6ct";
            QT_SCALE_FACTOR = "1";
            QT_AUTO_SCREEN_SCALE_FACTOR = "1";
            PLASMA_USE_QT_SCALING = "1";
            KWIN_TRIPLE_BUFFER = "1";
        };
    };
}
