{ pkgs, ... }:

let
    firefoxStableDesktopItem = pkgs.makeDesktopItem rec {
        type = "Application";
        terminal = false;
        name = "firefox-stable";
        desktopName = "Firefox Stable";
        exec = "firefox-stable -P \"Stable\" %u";
        icon = "/home/me/Mega/Images/Icons/Apps/firefox.png";
        startupWMClass = "firefox-stable";
        mimeTypes = [
            "application/pdf"
            "application/rdf+xml"
            "application/rss+xml"
            "application/xhtml+xml"
            "application/xhtml_xml"
            "application/xml"
            "image/gif"
            "image/jpeg"
            "image/png"
            "image/webp"
            "text/html"
            "text/xml"
            "x-scheme-handler/http"
            "x-scheme-handler/https"
        ];
        categories = [ "Network" "WebBrowser" ];
        actions = {
            NewWindow = {
                name = "Open a New Window";
                exec = "firefox-stable -P \"Stable\" --new-window %u";
            };
            NewPrivateWindow = {
                name = "Open a New Private Window";
                exec = "firefox-stable -P \"Stable\" --private-window %u";
            };
            ProfileSelect = {
                name = "Select a Profile";
                exec = "firefox-stable --ProfileManager";
            };
        };
    };

    # Firefox enterprise policy. The prefs go through the `Preferences`
    # policy with Status = "default": applied at startup, still user-editable
    # in about:config. (An earlier `UserPreferences` key here was not a real
    # policy name and was silently ignored, so none of these had ever taken
    # effect.)
    firefoxStablePrefs = {
        "media.ffmpeg.vaapi.enabled" = true;
        "media.hardware-video-decoding.force-enabled" = true;
        "media.rdd-ffvpx.enabled" = false;
        "media.navigator.mediadatadecoder_vpx_enabled" = true;
        "media.ffvpx.enabled" = false;
        "gfx.webrender.all" = true;
        "layers.acceleration.force-enabled" = true;
        "widget.dmabuf.force-enabled" = true;

        # Firefox's AI chatbot sidebar → the local Open WebUI (ai.nix), not a
        # cloud provider. Selected-text prompts arrive as ?q=, which Open WebUI
        # accepts; nothing leaves the machine.
        "browser.ml.chat.enabled" = true;
        "browser.ml.chat.provider" = "http://localhost:8180";
        "browser.ml.chat.hideLocalhost" = false;
    };

    firefoxStablePolicies = {
        policies = {
            DisableAppUpdate = true;
            Preferences = pkgs.lib.mapAttrs (_: v: { Value = v; Status = "default"; }) firefoxStablePrefs;
        };
    };

    firefoxStableWrapped = pkgs.runCommand "firefox-stable" {
        nativeBuildInputs = [ pkgs.makeWrapper ];
    } ''
mkdir -p $out/bin $out/lib/firefox-stable/distribution
echo '${builtins.toJSON firefoxStablePolicies}' > $out/lib/firefox-stable/distribution/policies.json
makeWrapper ${pkgs.firefox-bin}/bin/firefox $out/bin/firefox-stable \
 --set MOZ_DISTRIBUTION_DIR "$out/lib/firefox-stable" \
 --set MOZ_DESKTOP_FILE_NAME firefox-stable
    '';
in {
    environment.systemPackages = [
        firefoxStableWrapped

        #-- Create desktop entry.
        firefoxStableDesktopItem
    ];
}

# <> #
