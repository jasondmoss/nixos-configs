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
            services = {
                login = {
                    enableKwallet = true;
                };

                ly = {
                    kwallet.enable = true;
                };

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
