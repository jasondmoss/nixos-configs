# browsers.nix
#
# Browser policy and wiring: the nixpkgs Firefox (programs.firefox), Firefox
# Nightly as the default for links and HTML, the browsers 1Password may talk
# to, and Chrome's external-extension directory. The browser packages
# themselves are listed in ../system/packages.nix (network-web) and built by
# the overlays in ../system/nixpkgs.nix (Nightly wrapper, Chrome flags,
# Unclutter).
{ pkgs, ... }: {
    programs = {
        # The nixpkgs Firefox (`firefox.desktop`): the Stable profile, and the
        # binary behind the Claude Code profile launcher in
        # ../packages/claude-code-browser. Not the default browser — that is
        # Firefox Nightly (MIME defaults below). Installed through
        # programs.firefox rather than as a plain package so it carries the
        # same policies as the Nightly wrapper: hardware video decode on the
        # NVIDIA VAAPI path, the AI chatbot sidebar pointed at the local Open
        # WebUI (../services/ai.nix) instead of a cloud provider, and Smart
        # Window's assistant on local Ollama.
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

                # Smart Window's custom assistant → Ollama's OpenAI-compatible
                # API, not Open WebUI (why: packages/firefox-nightly).
                "browser.smartwindow.customEndpoint" = "http://127.0.0.1:11434/v1";
                "browser.smartwindow.model" = "qwen3.5:4b";
            };
        };
    };

    # Firefox Nightly handles links and HTML everywhere.
    xdg.mime.defaultApplications = {
        "text/html" = "firefox-nightly.desktop";
        "x-scheme-handler/http" = "firefox-nightly.desktop";
        "x-scheme-handler/https" = "firefox-nightly.desktop";
        "x-scheme-handler/about" = "firefox-nightly.desktop";
        "x-scheme-handler/unknown" = "firefox-nightly.desktop";
    };

    environment = {
        # firefox-stable is a wrapper installed by ../packages/firefox-stable,
        # not a pkgs attribute — reference it via the system profile.
        # sessionVariables.DEFAULT_BROWSER = "/run/current-system/sw/bin/firefox-stable";
        sessionVariables.DEFAULT_BROWSER = "/run/current-system/sw/bin/firefox-nightly";

        etc = {
            # Browsers allowed to talk to the 1Password desktop app.
            "1password/custom_allowed_browsers" = {
                text = ''
firefox
google-chrome-stable
                '';
                mode = "0755";
            };

            # Google Chrome external extensions. The Chrome package
            # (../system/nixpkgs.nix) symlinks its <install dir>/extensions/
            # to this directory; every <id>.json in it names a local CRX that
            # Chrome installs and keeps up to date with external_version. Only
            # Unclutter for now.
            "opt/chrome/extensions".source =
                "${pkgs.unclutter}/share/unclutter/chrome-external";
        };
    };
}

# <> #
