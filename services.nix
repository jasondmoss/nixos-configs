{ lib, pkgs, identity, ... }: {
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
    };

    systemd = {
        services.nix-index-database-update = {
            description = "Update nix-index database";
            serviceConfig = {
                Type = "oneshot";
                # Run as your user so database is available in ~/.cache/nix-index
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
                    ExecStart = "${pkgs.notes}/bin/notes";
                    Restart = "on-failure";

                    # Ensures the app finds the Wayland/X11 socket.
                    PassEnvironment = [ "DISPLAY" "WAYLAND_DISPLAY" "XDG_RUNTIME_DIR" ];
                };
            };
        };
    };
}

# <> #
