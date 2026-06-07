{ config, ... }: {
	security = {
        rtkit.enable = true;
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

                ly = {
                    kwallet.enable = true;
                };

                kwallet = {
                    kwallet.enable = true;
                };
            };
        };

        sudo = {
            enable = true;
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
