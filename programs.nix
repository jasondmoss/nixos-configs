{ pkgs, ... }: {
    programs = {
        bash.completion.enable = true;
        command-not-found.enable = false;
        direnv.enable = true;
        gamemode.enable = true;
        kdeconnect.enable = true;
        mtr.enable = true;
        nix-ld.enable = true;
        xwayland.enable = true;

        steam = {
            enable = true;
            # No game servers are hosted here — keep 27015 closed.
            dedicatedServer.openFirewall = false;
            remotePlay.openFirewall = true;
        };

        ssh = {
            startAgent = true;
            askPassword = pkgs.lib.mkForce "${pkgs.kdePackages.ksshaskpass.out}/bin/ksshaskpass";

            extraConfig = ''
AddKeysToAgent yes

Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_2026_jasondmoss
    IdentitiesOnly yes

Host github.com-work
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_2026_originoutside
    IdentitiesOnly yes

Host gitlab.com-gitlab
    HostName gitlab.com
    User git
    IdentityFile ~/.ssh/id_ed25519_2026_gitlab
    IdentitiesOnly yes

Host bitbucket.org
    HostName bitbucket.org
    User git
    IdentityFile ~/.ssh/id_ed25519_2026_bitbucket
    IdentitiesOnly yes

Host pantheon.io *.pantheon.io
    IdentityFile ~/.ssh/id_rsa
    IdentitiesOnly yes

            '';
        };

        gnupg.agent = {
            enable = true;
            pinentryPackage = pkgs.pinentry-qt;
        };

        git = {
            enable = true;
            lfs.enable = true;

            config = {
                credential.helper = "libsecret";
                init.defaultBranch = "main";

                # Global aliases for identity management.
                alias = {
                    whoami = "!git config user.email && git config user.name";
                    id = "!echo '--- Identity ---' && git whoami && echo '--- Remote ---' && git remote -v";
                };

                includeIf = {
                    # GitHub
                    "gitdir/i:/home/me/Repository/work/origin/" .path = "/etc/gitconfig.work";
                    "gitdir/i:/home/me/Repository/work/mmgy/" .path = "/etc/gitconfig.bitbucket";
                    "gitdir/i:/home/me/Repository/personal/" .path = "/etc/gitconfig.personal";
                    # Fallback for your main config repo if it's not in the personal folder.
                    "gitdir/i:/home/me/Repository/system/" .path = "/etc/gitconfig.personal";

                    # GitLab
                    "gitdir/i:/home/me/Repository/work/cyan-solutions/" .path = "/etc/gitconfig.gitlab";
                };
            };
        };

        nix-index = {
            enable = true;
            enableBashIntegration = true;
        };

        neovim = {
            enable = true;
            defaultEditor = true;
            viAlias = true;
            vimAlias = true;
            withNodeJs = true;
            withPython3 = true;
        };

        # The nixpkgs Firefox (`firefox.desktop`): the Stable profile, and the
        # binary behind the Claude Code profile launcher in
        # packages/claude-code-browser. Not the default browser — that is
        # Firefox Nightly (MIME defaults in desktop/plasma.nix). Installed here
        # rather than in packages.nix so it carries the same policies as the
        # Nightly wrapper: hardware video decode on the NVIDIA VAAPI path, and
        # the AI chatbot sidebar pointed at the local Open WebUI (ai.nix)
        # instead of a cloud provider.
        firefox = {
            enable = true;
            policies.DisableAppUpdate = true;
            # Never offer to become the default browser. On 2026-09-13 the
            # Claude Code profile took over http/https/text/html in
            # ~/.config/mimeapps.list this way, so every app (Wavebox, KDE)
            # opened links in it instead of Nightly.
            policies.DontCheckDefaultBrowser = true;
            # "default": applied at startup, still editable in about:config.
            preferencesStatus = "default";
            preferences = {
                "media.ffmpeg.vaapi.enabled" = true;
                "media.hardware-video-decoding.force-enabled" = true;
                "media.rdd-ffvpx.enabled" = false;
                "media.navigator.mediadatadecoder_vpx_enabled" = true;
                "media.ffvpx.enabled" = false;
                "gfx.webrender.all" = true;
                "layers.acceleration.force-enabled" = true;
                "widget.dmabuf.force-enabled" = true;
                "browser.ml.chat.enabled" = true;
                "browser.ml.chat.provider" = "http://localhost:8180";
                "browser.ml.chat.hideLocalhost" = false;
            };
        };

        _1password.enable = true;
        _1password-gui = {
            enable = true;
            # Local unix user(s) allowed to use 1Password's polkit policy
            # (system-authentication unlock). Must be a real account here.
            polkitPolicyOwners = [ "me" ];
            package = pkgs._1password-gui;
        };
    };
}

# <> #
