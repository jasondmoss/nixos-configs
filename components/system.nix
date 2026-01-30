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
                ssh-eager-load = {
                    description = "Eagerly load default SSH keys into agent";
                    wantedBy = [ "graphical-session.target" ];
                    partOf = [ "graphical-session.target" ];
                    unitConfig.ConditionEnvironment = "SSH_AUTH_SOCK";

                    serviceConfig = {
                        Type = "oneshot";
                        # -q: Quiet mode
                        # By default, this adds ~/.ssh/id_rsa, id_ed25519, etc.
                        # If you have custom key names, append them here (e.g., ~/.ssh/my_custom_key)
                        ExecStart = "${pkgs.openssh}/bin/ssh-add -q %h/.ssh/id_ed25519_2026_jasondmoss %h/.ssh/id_ed25519_2026_originoutside";
                        RemainAfterExit = true;
                    };
                };
            };
        };
    };
}

# <> #
