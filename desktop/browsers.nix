# browsers.nix
#
{ pkgs, ... }: {
    programs = {
        firefox = {
            enable = true;
            policies.DisableAppUpdate = true;
            policies.DontCheckDefaultBrowser = true;

            # Nightly's Vulkan Video decoder (FFmpegVulkanVideoDecoder) off:
            # on Nightly 162.0a1 (builds 20261115/16) + NVIDIA 615.78.08 it
            # decodes YouTube's 1080p H.264 with stale reference frames
            # (smeared blocks at scene changes and after every seek, 0
            # dropped frames). Off = the VA-API/NVDEC path below, which
            # plays the same stream clean.
            #
            # Status "user", not "default" like `preferences`: as a default-
            # branch value the main Nightly profile ignored it (still Vulkan),
            # while the Claude profile and fresh profiles honoured it — cause
            # not found. A user-branch value is what was seen to work. It is
            # written into each profile's prefs.js, so dropping this entry does
            # not undo it: set Status = "clear" for one rebuild + browser start,
            # or reset the pref in about:config. Re-test before removing:
            # youtube.com/watch?v=bf3sP68MAa8 at 1080p, 1:12-1:15.
            policies.Preferences."media.hardware-video-decoding-vulkan.enabled" = {
                Value = false;
                Status = "user";
            };

            # Hardware decoding on NVIDIA needs this force-enable (off = all
            # hardware decoding off, Vulkan included). Also Status "user": as a
            # default-branch value the main Nightly profile never attempted
            # VA-API (no `libva info` from its RDD, software decode once Vulkan
            # was off), while the Claude profile got VA-API from the same policy.
            policies.Preferences."media.hardware-video-decoding.force-enabled" = {
                Value = true;
                Status = "user";
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

            "opt/chrome/extensions".source =
                "${pkgs.unclutter}/share/unclutter/chrome-external";
        };
    };
}

# <> #
