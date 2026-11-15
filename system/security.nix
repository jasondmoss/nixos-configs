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

        # No pam.sshAgentAuth: it let the one key in authorized_keys.d grant
        # passwordless sudo to anything holding a forwarded agent, for an
        # inbound SSH path that is not in use. sudo asks for the password.
        pam = {
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
        };
    };

    services.fail2ban = {
        enable = true;
        maxretry = 5;
        bantime = "1h";
    };
}

# <> #
