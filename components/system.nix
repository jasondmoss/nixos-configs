{ lib, pkgs, ... }: {
    system = {
        activationScripts = {
            makeWorkDir = {
                text = ''
mkdir -p /home/jason/Repository/work/origin
                '';
                deps = [ "users" ];
            };

            megasyncUserService = {
                text = ''
mkdir -p /home/me/.config/systemd/user
ln -sf /etc/systemd/user/megasync.service /home/me/.config/systemd/user/megasync.service
                '';
                deps = [ "users" ];
            };
        };
    };

    systemd = {
        packages = [ pkgs.megasync ];

        services = {
            nix-index-database-update = {
                description = "Update nix-index database";
                serviceConfig = {
                    Type = "oneshot";
                    # Run as your user so the database is available in ~/.cache/nix-index
                    User = "me";
                    ExecStart = "${pkgs.nix-index}/bin/nix-index";
                };
            };
        };

        timers = {
            nix-index-database-update = {
                description = "Weekly update of nix-index database";

                timerConfig = {
                    OnCalendar = "weekly";
                    Persistent = true; # Run immediately if the system was off during scheduled time
                };

                wantedBy = [ "timers.target" ];
            };
        };

        user = {
            services = {
                ssh-key-pollen = {
                    description = "Load SSH keys into agent via KWallet";
                    wantedBy = [ "graphical-session.target" ];
                    partOf = [ "graphical-session.target" ];

                    serviceConfig = {
                        ExecStart = lib.concatStringsSep " && " [
                            "${pkgs.bash}/bin/bash -c '${pkgs.openssh}/bin/ssh-add %h/.ssh/id_ed25519_2026_jasondmoss'"
                            "${pkgs.bash}/bin/bash -c '${pkgs.openssh}/bin/ssh-add %h/.ssh/id_ed25519_2026_originoutside'"
                            "${pkgs.bash}/bin/bash -c '${pkgs.openssh}/bin/ssh-add %h/.ssh/id_ed25519_2026_gitlab < /dev/null'"
                        ];
                        Type = "oneshot";
                        RemainAfterExit = "yes";
                    };
                };

                megasync = {
                    description = "MEGAsync Cloud Sync application";
                    after    = [ "graphical-session.target" ];
                    wantedBy = [ "graphical-session.target" ];

                    serviceConfig = {
                        Type       = "simple";
                        ExecStart  = "${pkgs.megasync}/bin/megasync";
                        Restart    = "on-failure";
                        RestartSec = "5s";
                    };
                };

                notes = {
                    description = "Notes Desktop Application";
                    wantedBy = [ "graphical-session.target" ];
                    partOf = [ "graphical-session.target" ];

                    serviceConfig = {
                        Type = "simple";
#                        ExecStartPre = "${pkgs.coreutils}/bin/sleep 5s";
                        ExecStart = "${pkgs.notes}/bin/notes";
                        Restart = "on-failure";

                        # Ensures the app finds the Wayland/X11 socket.
                        PassEnvironment = [ "DISPLAY" "WAYLAND_DISPLAY" "XDG_RUNTIME_DIR" ];
                    };
                };
            };
        };
    };
}

# <> #
