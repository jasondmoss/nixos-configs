{ config, ... }: {
    security = {
        protectKernelImage = true;
        polkit = {
            enable = true;

            extraConfig = ''
polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.systemd1.run" &&
        subject.isInGroup("wheel")
    ) {
        return polkit.Result.AUTH_KEEP;
    }
});
            '';
        };

        pam = {
            sshAgentAuth = {
                enable = true;
            };

            services = {
                login = {
                    enableKwallet = true;
                };

                # Ly's PAM service — re-enable alongside the ly block in
                # ../desktop/plasma.nix. Harmless if left on, but the service is
                # dead weight while SDDM is the greeter.
                #ly = {
                #    kwallet.enable = true;
                #};

                kwallet = {
                    kwallet.enable = true;
                };
            };
        };

        pki = {
            certificateFiles = [
                /home/me/.lando/certs/LandoCA.crt
            ];
        };

        sudo = {
            enable = true;
            execWheelOnly = true;
            extraConfig = ''
# Keep SSH_AUTH_SOCK so that pam_ssh_agent_auth.so can do its magic.
Defaults env_keep+=SSH_AUTH_SOCK
            '';
        };
    };

    services.fail2ban = {
        enable = true;
        maxretry = 5;
        bantime = "1h";
    };
}

# <> #
