{ pkgs, ... }: {
    systemd = {
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

    system = {
        activationScripts = {
            makeWorkDir = {
                text = "mkdir -p /home/jason/Repository/origin";
                deps = [ "users" ];
            };
        };
    };
}

# <> #
