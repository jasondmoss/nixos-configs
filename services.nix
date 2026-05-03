{ lib, pkgs, ... }:
let
    identity = import ./identity.nix;
in {
    services = {
        dbus.enable = true;
        devmon.enable = true;
        fstrim.enable = true;
        gnome.gcr-ssh-agent.enable = false;
        gnome.gnome-keyring.enable = true;
        gpm.enable = true;
        irqbalance.enable = true;
        openssh.settings.AllowUsers = [ identity.userHandle ];
        pcscd.enable = true;
        sysstat.enable = true;
        systembus-notify.enable = lib.mkForce true;

        earlyoom = {
            enable = true;
            enableNotifications = true;
            freeMemThreshold = 5;   # % of RAM
            freeSwapThreshold = 10; # % of swap
        };


        locate = {
            enable = true;
            interval = "hourly";
            package = pkgs.mlocate;
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

        snapper = {
            cleanupInterval = "1d";
            snapshotInterval = "hourly";

            configs = {
                home = {
                    SUBVOLUME = "/home";
                    ALLOW_USERS = [ identity.userHandle ];
                    TIMELINE_CREATE = true;
                    TIMELINE_CLEANUP = true;
                    TIMELINE_LIMIT_HOURLY = "10";
                    TIMELINE_LIMIT_DAILY = "7";
                    TIMELINE_LIMIT_WEEKLY = "4";
                    TIMELINE_LIMIT_MONTHLY = "6";
                };

                repository = {
                    SUBVOLUME = "${identity.userHome}/Repository";
                    ALLOW_USERS = [ identity.userHandle ];
                    TIMELINE_CREATE = true;
                    TIMELINE_CLEANUP = true;
                    TIMELINE_LIMIT_HOURLY = "10";
                    TIMELINE_LIMIT_DAILY = "7";
                    TIMELINE_LIMIT_WEEKLY = "4";
                    TIMELINE_LIMIT_MONTHLY = "6";
                };
            };
        };
    };

    systemd = {
        packages = [ pkgs.megasync ];

        services.nix-index-database-update = {
            description = "Update nix-index database";
            serviceConfig = {
                Type = "oneshot";
                # Run as your user so the database is available in ~/.cache/nix-index
                User = identity.userHandle;
                ExecStart = "${pkgs.nix-index}/bin/nix-index";
            };
        };

        timers.nix-index-database-update = {
            description = "Weekly update of nix-index database";

            timerConfig = {
                OnCalendar = "weekly";
                Persistent = true; # Run immediately if the system was off during scheduled time
            };

            wantedBy = [ "timers.target" ];
        };

        user.services = {
            ssh-key-pollen = {
                description = "Load SSH keys into agent via KWallet";
                wantedBy = [ "graphical-session.target" ];
                partOf = [ "graphical-session.target" ];

                serviceConfig = {
                    ExecStart = lib.concatStringsSep " && " [
                        "${pkgs.bash}/bin/bash -c '${pkgs.openssh}/bin/ssh-add %h/.ssh/id_ed25519_2026_jasondmoss'"
                        "${pkgs.bash}/bin/bash -c '${pkgs.openssh}/bin/ssh-add %h/.ssh/id_ed25519_2026_originoutside'"
                        "${pkgs.bash}/bin/bash -c '${pkgs.openssh}/bin/ssh-add %h/.ssh/id_ed25519_2026_bitbucket'"
                        "${pkgs.bash}/bin/bash -c '${pkgs.openssh}/bin/ssh-add %h/.ssh/id_ed25519_2026_gitlab < /dev/null'"
                    ];
                    Type = "oneshot";
                    RemainAfterExit = "yes";
                };
            };

            megasync = {
                description = "MEGAsync Cloud Sync application";
                after = [ "graphical-session.target" ];
                wantedBy = [ "graphical-session.target" ];

                serviceConfig = {
                    Type = "simple";
                    ExecStart = "${pkgs.megasync}/bin/megasync";
                    Restart = "on-failure";
                    RestartSec = "5s";
                };
            };

            notes = {
                description = "Notes Desktop Application";
                wantedBy = [ "graphical-session.target" ];
                partOf = [ "graphical-session.target" ];

                serviceConfig = {
                    Type = "simple";
#                    ExecStartPre = "${pkgs.coreutils}/bin/sleep 5s";
                    ExecStart = "${pkgs.notes}/bin/notes";
                    Restart = "on-failure";

                    # Ensures the app finds the Wayland/X11 socket.
                    PassEnvironment = [ "DISPLAY" "WAYLAND_DISPLAY" "XDG_RUNTIME_DIR" ];
                };
            };
        };
    };

    system.activationScripts.megasyncUserService = {
        text = ''
mkdir -p ${identity.userHome}/.config/systemd/user
ln -sf /etc/systemd/user/megasync.service ${identity.userHome}/.config/systemd/user/megasync.service
        '';
        deps = [ "users" ];
    };
}

# <> #
