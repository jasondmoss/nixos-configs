# browsers.nix
#
{ pkgs, ... }: {
    programs = {
        firefox = {
            enable = true;
            policies = {
                DisableAppUpdate = true;
                DontCheckDefaultBrowser = true;

                Preferences = {
                    "media.hardware-video-decoding-vulkan.enabled" = {
                        Value = false;
                        Status = "user";
                    };
                    "media.hardware-video-decoding.force-enabled" = {
                        Value = false;
                        Status = "user";
                    };
                    "media.suspend-background-video.enabled" = {
                        Status = "clear";
                    };
                };
            };

            preferencesStatus = "default";
            preferences = {
                "media.ffmpeg.vaapi.enabled" = true;
                "media.rdd-ffvpx.enabled" = false;
                "media.navigator.mediadatadecoder_vpx_enabled" = true;
                "media.ffvpx.enabled" = false;
                "gfx.webrender.all" = true;
                "layers.acceleration.force-enabled" = true;
                "widget.dmabuf.force-enabled" = true;
                "browser.ml.chat.enabled" = false;
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

            # Unclutter CRX for Google Chrome — retired 2026-11-20.
            #"opt/chrome/extensions".source =
            #    "${pkgs.unclutter}/share/unclutter/chrome-external";
        };
    };
}

# <> #
