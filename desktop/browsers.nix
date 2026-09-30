# browsers.nix
#
{ pkgs, ... }: {
    programs = {
        firefox = {
            enable = true;
            policies.DisableAppUpdate = true;
            policies.DontCheckDefaultBrowser = true;
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
                "browser.smartwindow.customEndpoint" = "http://127.0.0.1:11434/v1";
                "browser.smartwindow.model" = "qwen3.5:4b";
            };
        };
    };

    xdg.mime.defaultApplications = {
        "text/html" = "firefox-nightly.desktop";
        "x-scheme-handler/http" = "firefox-nightly.desktop";
        "x-scheme-handler/https" = "firefox-nightly.desktop";
        "x-scheme-handler/about" = "firefox-nightly.desktop";
        "x-scheme-handler/unknown" = "firefox-nightly.desktop";
    };

    environment = {
        # sessionVariables.DEFAULT_BROWSER = "/run/current-system/sw/bin/firefox-stable";
        sessionVariables.DEFAULT_BROWSER = "/run/current-system/sw/bin/firefox-nightly";

        etc = {
            "1password/custom_allowed_browsers" = {
                text = ''
firefox
firefox-nightly
google-chrome-stable
                '';
                mode = "0755";
            };

            "opt/chrome/extensions".source =
                "${pkgs.unclutter}/share/unclutter/chrome-external";
        };
    };
}

# <> #
