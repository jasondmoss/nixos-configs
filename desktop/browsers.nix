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
            # dropped frames). Off = the VA-API/NVDEC path, which plays the
            # same stream clean. Moot while hardware decoding is off (below),
            # kept so re-enabling it does not bring Vulkan back.
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

            # Hardware video decoding OFF, i.e. software decode (2026-11-18).
            # On NVIDIA this pref is the only switch: true force-enables VA-API
            # (and Vulkan Video), false turns all hardware decoding off.
            # It was true from 2026-11-16 to 2026-11-18, and Nightly 162's
            # VA-API/NVDEC path froze YouTube in the main profile: picture
            # stuck, sound running, only a reload helped. That profile's own
            # trigger was resuming after a >5 s pause (Firefox frees the
            # decoder after media.dormant-on-pause-timeout-ms and rebuilds it
            # on Play); the frames kept reaching the compositor but the screen
            # kept the old one. The Claude profile also stalled at random
            # (3 of 5 fresh starts: ~10 frames, then nothing, at 60 fps rAF).
            # Until 2026-11-16 the main profile never honoured the default-
            # status true and decoded in software for months without
            # freezes, so that is the setup restored here. Status "user" so it
            # overrides the true now stored in each profile's prefs.js. In the
            # main profile it takes effect on the 2nd Nightly start after the
            # rebuild: graphics start-up reads prefs.js before the policies
            # are applied (2026-11-18: the 1st start still opened VA-API). Before
            # setting it back to true, re-test: pause a YouTube video >45 s,
            # resume, and watch the screen, not just currentTime.
            policies.Preferences."media.hardware-video-decoding.force-enabled" = {
                Value = false;
                Status = "user";
            };

            # Retired 2026-11-18: background-video decode suspension was turned
            # off on 2026-11-17 for the freeze above, but it was not the cause
            # (it froze again with it off). Status "clear" removes the user
            # value false that entry wrote into each profile's prefs.js, so
            # Firefox's default (true: hidden videos stop decoding after 10 s)
            # is back. Can be commented out after one Nightly start.
            policies.Preferences."media.suspend-background-video.enabled" = {
                Status = "clear";
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
