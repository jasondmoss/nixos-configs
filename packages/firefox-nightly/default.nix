{
    lib,  stdenv,  makeWrapper,  autoPatchelfHook,  makeDesktopItem,
    firefox-src,  libGL, libGLU, libevent, libffi, libjpeg, libpng,
    libvpx, libxml2,  fontconfig, freetype, zlib, dbus, dbus-glib, nspr,
    nss,  atk, at-spi2-atk, cairo, gdk-pixbuf, glib, gtk3, pango,  xorg,
    alsa-lib, wayland, mesa, libkrb5, libva
}:
let
    identity = import ../../identity.nix;

    firefoxNightlyDesktopItem = makeDesktopItem {
        type = "Application";
        terminal = false;
        name = "firefox-nightly";
        desktopName = "Firefox Nightly";
        exec = "firefox-nightly -P \"Nightly\" %u";
        icon = "${identity.userHome}/Mega/Images/Icons/Apps/firefox-developer-edition-alt.png";
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
in stdenv.mkDerivation {
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
