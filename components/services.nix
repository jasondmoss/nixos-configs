{ config, pkgs, ... }: {
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
            enable = false;
            videoDrivers = [ "nvidia" ];
            upscaleDefaultCursor = true;

#            displayManager.sessionCommands = ''
## Manual autostart
#(sleep 10s;${config.users.users.me.home}/.local/bin/megasync-wrapper.sh) &
#(sleep 1m;/run/current-system/sw/bin/notes) &
#            '';
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
    };
}

# <> #
