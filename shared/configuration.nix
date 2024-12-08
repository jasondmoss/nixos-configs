{ config, lib, pkgs,   options, ... }:
let
    theme = import ./theme.nix;
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
                style = "slight";
            };
        };

        packages = with pkgs; [
            dotcolon-fonts
            freefont_ttf
            google-fonts
            jetbrains-mono
            liberation_ttf
            paratype-pt-sans
            paratype-pt-mono
            profont
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

        gnupg.agent = {
            enable = true;
            pinentryPackage = pkgs.pinentry-qt;
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

        dbus.enable = true;
        devmon.enable = true;
        gpm.enable = true;
        pcscd.enable = true;
        sysstat.enable = true;
        udev.enable = true;

        xserver = {
            enable = true;
            videoDrivers = [ "nvidia" ];
        };

        printing = {
            browsing = false;
            cups-pdf.enable = false;
            startWhenNeeded = false;
        };

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
                KbdInteractiveAuthentication = false;
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
                    #animation = "matrix";
                    #animation_timeout_sec = "20";
                    animation = "none";
                    input_len = "64";
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

        httpd = {
            enable = true;
            adminAddr = "me@localhost";
            user = "me";
            group = "users";
            extraModules = [ "http2" ];
            enablePHP = true;

#            phpPackage = pkgs.php83.buildEnv {
#                extensions = ({ enabled, all }: enabled);
#                extraConfig = ''
#memory_limit = 2048M
#                '';
#            };

            phpPackage = pkgs.php84.buildEnv {
                extensions = ({ enabled, all }: enabled);
                extraConfig = ''
memory_limit = 2048M
                '';
            };

            phpOptions = ''
allow_url_fopen = On
allow_url_include = On
display_errors = On
display_startup_errors = On
max_execution_time = 10000
max_input_time = 3000
mbstring.http_input = pass
mbstring.http_output = pass
mbstring.internal_encoding = pass
memory_limit = 2048M
post_max_size = 2048M
session.cookie_samesite = "Strict"
upload_max_filesize = 2048M
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

            loadModels = [
                "codestral"
                "yi-coder"
            ];
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
        useDHCP = lib.mkDefault true;

        firewall = {
            enable = true;
            allowPing = true;

            allowedTCPPorts = [ 22 80 443 1025 1143 33728 ];
            allowedUDPPorts = [];
        };

        networkmanager = {
            enable = true;
            insertNameservers = [ "127.0.0.1" ];
        };
    };

    security = {
        rtkit.enable = true;
        polkit.enable = true;

        pam = {
            sshAgentAuth = {
                enable = true;
            };

            services = {
                kwallet = {
                    kwallet.enable = true;
                };

                ly = {
                    kwallet.enable = true;
                };
            };
        };

        sudo = {
            enable = true;
            wheelNeedsPassword = false;
            extraConfig = ''
Defaults:me !authenticate
# Keep SSH_AUTH_SOCK so that pam_ssh_agent_auth.so can do its magic.
Defaults env_keep+=SSH_AUTH_SOCK
            '';
        };
    };

    documentation = {
        enable = true;
        man.enable = true;
        dev.enable = true;
    };

    systemd = {
        extraConfig = "DefaultTimeoutStopSec=10s";
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

    environment = {
        variables = {
            __GL_ALLOW_UNOFFICIAL_PROTOCOL = "1";
            __GL_GSYNC_ALLOWED = "1";
            __GL_SHADER_CACHE = "1";
            __GL_THREADED_OPTIMIZATION = "1";
            __GL_VRR_ALLOWED = "0";
            __GLX_VENDOR_LIBRARY_NAME = "nvidia";
            _JAVA_AWT_WM_NONREPARENTING = "1";

            DISABLE_QT5_COMPAT = "1";
            EGL_PLATFORM = "wayland";
            ELECTRON_OZONE_PLATFORM_HINT = "wayland";
            GBM_BACKEND = "nvidia-drm";
            GBM_BACKENDS_PATH = "/run/opengl-driver/lib/gbm";
            LIBVA_DRIVER_NAME = "nvidia";
            NIXOS_OZONE_WL = "1";
            NVD_BACKEND = "direct";
            SDL_VIDEODRIVER = "wayland";
            VDPAU_DRIVER = "va_gl";
            WLR_BACKEND = "vulkan";
            WLR_DRM_DEVICES = "/dev/dri/card0";
            WLR_DRM_NO_ATOMIC = "1";
            WLR_NO_HARDWARE_CURSORS = "1";

            #QT_QPA_PLATFORM = "wayland;xcb";  # Breaks Megasync.
            #QT_QPA_PLATFORMTHEME = "qt6ct";   # Breaks Megasync.

            QT_AUTO_SCREEN_SCALE_FACTOR = "1";
            QT_SCALE_FACTOR = "1";
            QT_SCALE_FACTOR_ROUNDING_POLICY = "RoundPreferFloor";
            QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";

            PLASMA_USE_QT_SCALING = "1";

            KWIN_TRIPLE_BUFFER = "1";

            MOZ_DISABLE_GMP_SANDBOX = "1";
            MOZ_DISABLE_RDD_SANDBOX = "1";
            MOZ_ENABLE_WAYLAND = "1";
            MOZ_X11_EGL = "1";

            SSH_ASKPASS = lib.mkForce "/run/current-system/sw/bin/ksshaskpass";
            SSH_ASKPASS_REQUIRE = "prefer";

            XDG_BIN_HOME = "/home/me/.local/bin";
            XDG_CACHE_HOME = "/home/me/.cache";
            XDG_CONFIG_HOME = "/home/me/.config";
            XDG_DATA_HOME = "/home/me/.local/share";
            XDG_SESSION_TYPE = "wayland";
            XDG_CURRENT_DESKTOP = "KDE";
            XDG_MENU_PREFIX = "kde-";

            XCURSOR_THEME = "ComixCursors";

            #GDK_DPI_SCALE = "0.5";
            #GDK_SCALE = "2";
            #GDK_USE_XFT = "1";

            GST_PLUGIN_SYSTEM_PATH_1_0 = lib.makeSearchPathOutput "lib" "lib/gstreamer-1.0" [
                pkgs.gst_all_1.gst-editing-services
                pkgs.gst_all_1.gst-libav
                pkgs.gst_all_1.gst-plugins-bad
                pkgs.gst_all_1.gst-plugins-base
                pkgs.gst_all_1.gst-plugins-good
                pkgs.gst_all_1.gst-plugins-ugly
                pkgs.gst_all_1.gstreamer
            ];

            DEFAULT_BROWSER = "/run/current-system/sw/bin/firefox-nightly";
        };
    };

}
