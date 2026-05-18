{ pkgs, ... }:

let
    identity = import ../../identity.nix;

    firefoxStableDesktopItem = pkgs.makeDesktopItem rec {
        type = "Application";
        terminal = false;
        name = "firefox-stable";
        desktopName = "Firefox Stable";
        exec = "firefox-stable -P \"Stable\" %u";
        icon = "${identity.userHome}/Mega/Images/Icons/Apps/firefox.png";
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

    firefoxStablePolicies = {
        policies = {
            DisableAppUpdate = true;
            UserPreferences = {
                "media.ffmpeg.vaapi.enabled" = true;
                "media.hardware-video-decoding.force-enabled" = true;
                "media.rdd-ffvpx.enabled" = false;
                "media.navigator.mediadatadecoder_vpx_enabled" = true;
                "media.ffvpx.enabled" = false;
                "gfx.webrender.all" = true;
                "layers.acceleration.force-enabled" = true;
                "widget.dmabuf.force-enabled" = true;
            };
        };
    };

    firefoxStableWrapped = pkgs.runCommand "firefox-stable" {
        nativeBuildInputs = [ pkgs.makeWrapper ];
    } ''
mkdir -p $out/bin $out/lib/firefox-stable/distribution
echo '${builtins.toJSON firefoxStablePolicies}' > $out/lib/firefox-stable/distribution/policies.json
makeWrapper ${pkgs.firefox-bin}/bin/firefox $out/bin/firefox-stable \
 --set MOZ_DISTRIBUTION_DIR "$out/lib/firefox-stable"
    '';
in {
    environment.systemPackages = [
        firefoxStableWrapped

        #-- Create desktop entry.
        firefoxStableDesktopItem
    ];
}

# <> #
