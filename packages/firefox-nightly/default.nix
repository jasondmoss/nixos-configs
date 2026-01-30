{ pkgs, lib, ... }:
let

    firefoxNightlyDesktopItem = pkgs.makeDesktopItem {
        type = "Application";
        terminal = false;
        name = "firefox-nightly";
        desktopName = "Firefox Nightly";
        exec = "firefox-nightly -P \"Nightly\" %u";
        icon = "/home/me/Mega/Images/Icons/Apps/firefox-developer-edition-alt.png";
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
                exec = "firefox-nightly -P \"Nightly\" --new-window %u";
            };

            NewPrivateWindow = {
                name = "Open a New Private Window";
                exec = "firefox-nightly -P \"Nightly\" --private-window %u";
            };

            ProfileSelect = {
                name = "Select a Profile";
                exec = "firefox-nightly --ProfileManager";
            };
        };
    };

    # Define the hardware acceleration policies
    firefoxNightlyPolicies = {
        policies = {
            DisableAppUpdate = true;

            UserPreferences = {
                "media.ffmpeg.vaapi.enabled" = true;
                "media.rdd-ffvpx.enabled" = false;
                "media.navigator.mediadatadecoder_vpx_enabled" = true;
                "media.ffvpx.enabled" = false;
                "gfx.webrender.all" = true;
                "layers.acceleration.force-enabled" = true;
            };
        };
    };

in {

    environment.systemPackages = (with pkgs; [
        (pkgs.runCommand "latest.firefox-nightly-bin-wrapped" {
        nativeBuildInputs = [ pkgs.makeWrapper ];
        } ''
mkdir -p $out/bin
mkdir -p $out/lib/firefox-nightly/distribution

# Create the symlink
ln -s ${pkgs.latest.firefox-nightly-bin}/bin/firefox $out/bin/firefox-nightly

# Wrap the binary with environment variables for NVIDIA VA-API
wrapProgram $out/bin/firefox-nightly \
 --set LIBVA_DRIVER_NAME nvidia \
 --set MOZ_DISABLE_RDD_SANDBOX 1 \
 --set NVD_BACKEND direct

# Inject the policies JSON for preferences
echo '${builtins.toJSON firefoxNightlyPolicies}' > $out/lib/firefox-nightly/distribution/policies.json
        '')

        #-- Create desktop entry.
        firefoxNightlyDesktopItem
    ]);

}
