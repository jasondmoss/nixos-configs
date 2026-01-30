{ pkgs, ... }: {
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
            megasync = {
                description = "MEGAcmd Sync Client";

                after = [ "graphical-session.target" ];
                wantedBy = [ "graphical-session.target" ];
#                partOf = [ "graphical-session.target" ];

                serviceConfig = {
                    Type = "simple";
#                    ExecStartPre = "${pkgs.coreutils}/bin/sleep 5";
                    ExecStart = "${pkgs.megasync}/bin/megasync";
                    Restart = "on-failure";
                    RestartSec = "10s";

                    # Vital for Wayland/Plasma 6 to find the session
#                    Environment = "PATH=${pkgs.megasync}/bin:${pkgs.coreutils}/bin";

                    Environment = [
                        "QT_QPA_PLATFORM=wayland"
                        "XDG_CURRENT_DESKTOP=KDE"
                        "XDG_SESSION_TYPE=wayland"
                    ];
                };
            };

            nix-index-database-update = {
                description = "Update nix-index database";
                serviceConfig = {
                    Type = "oneshot";
                    # Run as your user so the database is available in ~/.cache/nix-index
                    User = "me";
                    ExecStart = "${pkgs.nix-index}/bin/nix-index";
                };
            };

            notes = {
                description = "Notes Desktop Application";
                # Ensure the service waits for the Plasma Wayland session
#                after = [ "graphical-session.target" ];
                wantedBy = [ "graphical-session.target" ];
                partOf = [ "graphical-session.target" ];

                serviceConfig = {
#                    Type = "simple";
                    ExecStartPre = "${pkgs.coreutils}/bin/sleep 30";
                    ExecStart = "${pkgs.notes}/bin/notes";
                    Restart = "on-failure";
#                    RestartSec = "3s";
                    # Ensures the app finds the Wayland/X11 socket.
                    PassEnvironment = [ "DISPLAY" "WAYLAND_DISPLAY" "XDG_RUNTIME_DIR" ];
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
                        ExecStart = "${pkgs.bash}/bin/bash -c '${pkgs.openssh}/bin/ssh-add %h/.ssh/id_ed25519_2026_jasondmoss %h/.ssh/id_ed25519_2026_originoutside < /dev/null'";
                        Type = "oneshot";
                        RemainAfterExit = "yes";
                    };
                };
            };
        };
    };
}

# <> #
