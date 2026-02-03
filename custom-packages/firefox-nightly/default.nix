{
    lib,
    stdenv,
    makeWrapper,
    autoPatchelfHook,
    makeDesktopItem,
    firefox-src,
    libGL, libGLU, libevent, libffi, libjpeg, libpng, libvpx, libxml2,
    fontconfig, freetype, zlib, dbus, dbus-glib, nspr, nss,
    atk, at-spi2-atk, cairo, gdk-pixbuf, glib, gtk3, pango,
    xorg, alsa-lib, wayland, mesa, libkrb5, libva
}:

let
    # Move the Desktop Item here, but we will install it in the derivation
    firefoxNightlyDesktopItem = makeDesktopItem {
        type = "Application";
        terminal = false;
        name = "firefox-nightly";
        desktopName = "Firefox Nightly";
        # We point directly to the binary name we create in the wrapper
        exec = "firefox-nightly -P \"Nightly\" %u";
        icon = "firefox-developer-edition-alt"; # Better to use system icon name or absolute path
        mimeTypes = [
            "application/pdf" "application/rdf+xml" "application/rss+xml"
            "application/xhtml+xml" "application/xhtml_xml" "application/xml"
            "image/gif" "image/jpeg" "image/png" "image/webp"
            "text/html" "text/xml" "x-scheme-handler/http" "x-scheme-handler/https"
        ];
        categories = [ "Network" "WebBrowser" ];
    };

    firefoxNightlyPolicies = {
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
in
stdenv.mkDerivation {
    pname = "firefox-nightly-wrapped";
    version = "latest";
    src = firefox-src;

    nativeBuildInputs = [ makeWrapper autoPatchelfHook ];

    buildInputs = [
        libGL libGLU libevent libffi libjpeg libpng libvpx libxml2
        fontconfig freetype zlib dbus dbus-glib nspr nss
        atk at-spi2-atk cairo gdk-pixbuf glib gtk3 pango
        xorg.libX11 xorg.libXcomposite xorg.libXcursor xorg.libXdamage
        xorg.libXext xorg.libXfixes xorg.libXi xorg.libXrandr
        xorg.libXrender xorg.libXt xorg.libXxf86vm xorg.libxcb
        xorg.libXinerama alsa-lib wayland mesa libkrb5 libva
  ];

    # Allow the build to find the 'firefox' binary in the source
    unpackPhase = "true";

    installPhase = ''
runHook preInstall

# Create destination
LIB_DIR="$out/lib/firefox-nightly"
mkdir -p "$LIB_DIR"

# The Mozilla source usually has a single 'firefox' or 'firefox-bin' dir.
# We find the actual directory containing the files.
SRC_DIR=$(find $src -maxdepth 2 -name "firefox" -type f -exec dirname {} \;)

# Copy all files and ensure we have write permissions to modify/patch them
cp -L -r $SRC_DIR/* "$LIB_DIR/"
chmod -R +w "$LIB_DIR"

# Policies
mkdir -p "$LIB_DIR/distribution"
echo '${builtins.toJSON firefoxNightlyPolicies}' > "$LIB_DIR/distribution/policies.json"

# Desktop Item
mkdir -p "$out/share/applications"
cp ${firefoxNightlyDesktopItem}/share/applications/* "$out/share/applications/"

# Ensure the binary is executable for the wrapper
chmod +x "$LIB_DIR/firefox"

# Create the wrapper
mkdir -p "$out/bin"
makeWrapper "$LIB_DIR/firefox" "$out/bin/firefox-nightly" \
 --set MOZ_ENABLE_WAYLAND 1 \
 --set LIBVA_DRIVER_NAME nvidia \
 --set MOZ_DISABLE_RDD_SANDBOX 1 \
 --set NVD_BACKEND direct

runHook postInstall
    '';

    meta = with lib; {
        description = "Firefox Nightly (Wrapped for NVIDIA/Wayland)";
        mainProgram = "firefox-nightly";
        platforms = platforms.linux;
    };
}



#{ pkgs, lib, fetchurl, ... }:
#let
#    firefoxNightlyDesktopItem = pkgs.makeDesktopItem {
#        type = "Application";
#        terminal = false;
#        name = "firefox-nightly";
#        desktopName = "Firefox Nightly";
#        exec = "firefox-nightly -P \"Nightly\" %u";
#        icon = "/home/me/Mega/Images/Icons/Apps/firefox-developer-edition-alt.png";
#        mimeTypes = [
#            "application/pdf"
#            "application/rdf+xml"
#            "application/rss+xml"
#            "application/xhtml+xml"
#            "application/xhtml_xml"
#            "application/xml"
#            "image/gif"
#            "image/jpeg"
#            "image/png"
#            "image/webp"
#            "text/html"
#            "text/xml"
#            "x-scheme-handler/http"
#            "x-scheme-handler/https"
#        ];
#        categories = [ "Network" "WebBrowser" ];
#        actions = {
#            NewWindow = {
#                name = "Open a New Window";
#                exec = "firefox-nightly -P \"Nightly\" --new-window %u";
#            };
#
#            NewPrivateWindow = {
#                name = "Open a New Private Window";
#                exec = "firefox-nightly -P \"Nightly\" --private-window %u";
#            };
#
#            ProfileSelect = {
#                name = "Select a Profile";
#                exec = "firefox-nightly --ProfileManager";
#            };
#        };
#    };
#
#    # Define the hardware acceleration policies
#    firefoxNightlyPolicies = {
#        policies = {
#            DisableAppUpdate = true;
#
#            UserPreferences = {
#                "media.ffmpeg.vaapi.enabled" = true;
#                "media.hardware-video-decoding.force-enabled" = true; # NEW: Bypass the blocklist
#                "media.rdd-ffvpx.enabled" = false;
#                "media.navigator.mediadatadecoder_vpx_enabled" = true;
#                "media.ffvpx.enabled" = false;
#                "gfx.webrender.all" = true;
#                "layers.acceleration.force-enabled" = true;
#                "widget.dmabuf.force-enabled" = true; # Helps with NVIDIA buffer sharing
#            };
#        };
#    };
#in {
#    environment.systemPackages = [
#        (pkgs.stdenv.mkDerivation {
#            pname = "latest-firefox-nightly-wrapped";
#            version = "latest";
#            src = pkgs.latest.firefox-nightly-bin;
#
#            nativeBuildInputs = [
#                pkgs.makeWrapper
#                pkgs.findutils
#                pkgs.autoPatchelfHook
#            ];
#
#            buildInputs = with pkgs; [
#                libGL libGLU libevent libffi libjpeg libpng libvpx libxml2
#                fontconfig freetype zlib dbus dbus-glib nspr nss
#                atk at-spi2-atk cairo gdk-pixbuf glib gtk3 pango
#                xorg.libX11 xorg.libXcomposite xorg.libXcursor xorg.libXdamage
#                xorg.libXext xorg.libXfixes xorg.libXi xorg.libXrandr
#                xorg.libXrender xorg.libXt xorg.libXxf86vm xorg.libxcb
#                xorg.libXinerama alsa-lib wayland mesa libkrb5 libva
#            ];
#
#            installPhase = ''
#DEST_LIB="$out/lib/firefox-nightly"
#mkdir -p "$DEST_LIB"
#
#REAL_BIN=$(find $src -type f -executable -name "firefox" | head -n 1)
#    [ -z "$REAL_BIN" ] && REAL_BIN=$(find $src -type f -executable -name "firefox-bin" | head -n 1)
#    SOURCE_DIR=$(dirname "$REAL_BIN")
#
#cp -r "$SOURCE_DIR"/* "$DEST_LIB/"
#chmod -R +w "$DEST_LIB"
#
#rm -rf "$DEST_LIB/distribution"
#mkdir -p "$DEST_LIB/distribution"
#echo '${builtins.toJSON firefoxNightlyPolicies}' > "$DEST_LIB/distribution/policies.json"
#
#mkdir -p $out/bin
#
## Wayland-Specific Wrapper
#makeWrapper "$DEST_LIB/firefox" "$out/bin/firefox-nightly" \
# --set MOZ_ENABLE_WAYLAND 1 \
# --set LIBVA_DRIVER_NAME nvidia \
# --set MOZ_DISABLE_RDD_SANDBOX 1 \
# --set NVD_BACKEND direct
#            '';
#        })
#
#        #-- Create desktop entry.
#        firefoxNightlyDesktopItem
#    ];
#}
