{ lib, pkgs, ... }: {
    system = {
        activationScripts = {
            makeWorkDir = {
                text = "mkdir -p /home/jason/Repository/origin";
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

                megasync-custom = {
                    description = "MEGAcmd Sync Client (Custom Autostart)";

                    # Using default.target is more reliable for user-services
                    # that need to be "found" by systemctl --user
                    wantedBy = [ "default.target" ];
                    after = [ "graphical-session.target" ];
                    partOf = [ "graphical-session.target" ];

                    startLimitIntervalSec = 0;

                    serviceConfig = {
                        Type = "simple";

                        # Clean lock and wait
                        ExecStartPre = [
                            "!${pkgs.bash}/bin/bash -c 'rm -f %h/.local/share/data/Mega\\ Limited/MEGAsync/megasync.lock'"
                            "${pkgs.coreutils}/bin/sleep 10"
                        ];

                        ExecStart = "${pkgs.megasync}/bin/megasync";
                        Restart = "always";
                        RestartSec = "10s";

                        Environment = [
                            "QT_QPA_PLATFORM=wayland"
                            "XDG_CURRENT_DESKTOP=KDE"
                            "XDG_SESSION_TYPE=wayland"
                        ];
                    };
                };

                notes = {
                    description = "Notes Desktop Application";
                    wantedBy = [ "graphical-session.target" ];
                    partOf = [ "graphical-session.target" ];

                    serviceConfig = {
                        Type = "simple";
                        ExecStartPre = "${pkgs.coreutils}/bin/sleep 30s";
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
