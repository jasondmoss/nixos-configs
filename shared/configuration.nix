{ config, lib, pkgs, channel,    ... }:
let
    theme = import ./theme.nix;
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
        #font = null;
        keyMap = "us";
        colors = theme.colors16;
    };

    programs = {
        kdeconnect.enable = true;
        mtr.enable = true;
        xwayland.enable = true;
        bash.completion.enable = true;

        ssh = {
#            startAgent = true;
            askPassword = pkgs.lib.mkForce "${pkgs.kdePackages.ksshaskpass.out}/bin/ksshaskpass";
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

        firefox = {
#            enable = true;
#            package = pkgs.firefox;
            policies.SearchEngines = {
                Default = "DuckDuckGo";
                Remove = [ "Bing" "Google" "Amazon.ca" "eBay" ];
            };
            preferences = {
                "widget.use-xdg-desktop-portal.file-picker" = 1;
            };
        };

        _1password.enable = true;
        _1password-gui = {
            enable = true;
            polkitPolicyOwners = [ "team-originoutside" ];
            package = pkgs._1password-gui-beta;
        };
    };

    services = {
        dbus.enable = true;
        devmon.enable = true;
        gpm.enable = true;
        pcscd.enable = true;
        sysstat.enable = true;

        smartd = {
            enable = true;
            autodetect = true;
        };

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

        udev = {
            enable = true;

            packages = [ pkgs.via ];
        };

        xserver = {
            enable = true;
            videoDrivers = [ "nvidia" ];
            upscaleDefaultCursor = true;

            displayManager.sessionCommands = ''
(sleep 10s;/run/current-system/sw/bin/1password) &
(sleep 30s;/run/current-system/sw/bin/megasync) &
(sleep 2m;/run/current-system/sw/bin/notes) &
            '';
        };

        locate = {
            enable = true;
            package = pkgs.mlocate;
            interval = "hourly";
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
            audio.enable = true;
            jack.enable = true;
            pulse.enable = true;

            alsa = {
                enable = true;
                support32Bit = true;
            };
        };

        displayManager = {
            ly = {
                enable = true;
                x11Support = false;
                settings = {
                    clear_password = true;
                    clock = "%c";
#                    animation = "matrix";
#                    animation_timeout_sec = "20";
                    animation = "none";
                    input_len = "64";
                    waylandsessions = "${pkgs.kdePackages.plasma-workspace}/share/wayland-sessions";
                };
            };

            defaultSession = "plasma";
        };

        desktopManager.plasma6 = {
           enable = true;
           enableQt5Integration = false;
        };

        httpd = {
            enable = true;
            adminAddr = "me@localhost";
            user = "me";
            group = "users";
            extraModules = [ "http2" ];
        };

        mysql = {
            enable = true;
            package = pkgs.mariadb;

            settings.mysqld = {
                transaction-isolation = "READ-COMMITTED";
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

#        n8n = {
#            enable = true;
#            openFirewall = true;
#            webhookUrl = "";
#            settings = {};
#        };

       ollama = {
           enable = true;
           acceleration = "cuda";

           # https://ollama.com/library
           loadModels = [
               "gemma3:latest"
           ];
       };

       open-webui = {
           enable = true;
       };
    };

    xdg.portal = {
        enable = true;
        xdgOpenUsePortal = true;
        config = {
            kde.default = [ "kde" "gtk" "gnome" ];
            kde."org.freedesktop.portal.FileChooser" = [ "kde" ];
            kde."org.freedesktop.portal.OpenURI" = [ "kde" ];
        };
        extraPortals = with pkgs; [
            xdg-desktop-portal
            xdg-desktop-portal-termfilechooser
            kdePackages.xdg-desktop-portal-kde
        ];
    };

    networking = {
        enableIPv6 = true;
        useDHCP = lib.mkDefault true;

        firewall = {
            enable = true;
            allowPing = true;
            checkReversePath = false;

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
                "33"
                "audio"
                "docker"
                "mlocate"
                "mysql"
                "navidrome"
                "networkmanager"
                "power"
                "video"
                "wheel"
                "wwwrun"
            ];
        };
    };

    environment = {
        etc = {
            "1password/custom_allowed_browsers" = {
                text = ''
firefox-nightly
vivaldi-bin
wavebox
                '';
                mode = "0755";
            };
        };

        variables = {
            _JAVA_AWT_WM_NONREPARENTING = "1";
            __GLX_VENDOR_LIBRARY_NAME = "nvidia";
            __GL_ALLOW_UNOFFICIAL_PROTOCOL = "1";
            __GL_GSYNC_ALLOWED = "1";
            __GL_SHADER_CACHE = "1";
            __GL_THREADED_OPTIMIZATION = "1";
            __GL_VRR_ALLOWED = "0";
            __NV_DISABLE_EXPLICIT_SYNC = "1";

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

            QT_AUTO_SCREEN_SCALE_FACTOR = "1";
            QT_QPA_PLATFORM = "wayland;xcb";
            QT_QPA_PLATFORMTHEME = "qt6ct";
            QT_SCALE_FACTOR = "1";
            QT_SCALE_FACTOR_ROUNDING_POLICY = "RoundPreferFloor";
            QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";

            KWIN_TRIPLE_BUFFER = "1";

            PLASMA_USE_QT_SCALING = "1";

            GSK_RENDERER = "ngl";

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

            GEMINI_API_KEY = "$(${pkgs.coreutils}/bin/cat /home/me/.config/gemini/api.key)";
        };
    };

}
