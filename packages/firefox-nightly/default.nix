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
                "media.hardware-video-decoding.force-enabled" = true; # NEW: Bypass the blocklist
                "media.rdd-ffvpx.enabled" = false;
                "media.navigator.mediadatadecoder_vpx_enabled" = true;
                "media.ffvpx.enabled" = false;
                "gfx.webrender.all" = true;
                "layers.acceleration.force-enabled" = true;
                "widget.dmabuf.force-enabled" = true; # Helps with NVIDIA buffer sharing
            };
        };
    };

in {

    environment.systemPackages = [
        (pkgs.runCommand "latest.firefox-nightly-bin-wrapped" {
            nativeBuildInputs = [ pkgs.makeWrapper ];
        } ''
# We look for a file named 'firefox' that is executable
REAL_BIN=$(find ${pkgs.latest.firefox-nightly-bin} -type f -executable -name "firefox" | head -n 1)

# If 'firefox' isn't found, try 'firefox-bin'
if [ -z "$REAL_BIN" ]; then
    REAL_BIN=$(find ${pkgs.latest.firefox-nightly-bin} -type f -executable -name "firefox-bin" | head -n 1)
fi

SOURCE_DIR=$(dirname "$REAL_BIN")
DEST_LIB="$out/lib/firefox-nightly"
mkdir -p "$DEST_LIB"

for item in "$SOURCE_DIR"/*; do
    basename=$(basename "$item")

    if [ "$basename" != "firefox" ] && [ "$basename" != "firefox-bin" ] && [ "$basename" != "distribution" ]; then
        ln -s "$item" "$DEST_LIB/$basename"
    fi
done

cp "$REAL_BIN" "$DEST_LIB/firefox"

mkdir -p "$DEST_LIB/distribution"
echo '${builtins.toJSON firefoxNightlyPolicies}' > "$DEST_LIB/distribution/policies.json"

mkdir -p $out/bin
makeWrapper "$DEST_LIB/firefox" "$out/bin/firefox-nightly" \
 --set LIBVA_DRIVER_NAME nvidia \
 --set MOZ_DISABLE_RDD_SANDBOX 1 \
 --set NVD_BACKEND direct \
 --set MOZ_X11_EGL 1
        '')

        #-- Create desktop entry.
        firefoxNightlyDesktopItem
    ];
}
