{ lib,  stdenv,  makeDesktopItem,  firefox-src }:

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
                "gfx.webrender.partial-present.force-disabled" = true;
            };
        };
    };
in
stdenv.mkDerivation {
    pname = "firefox-nightly-wrapped";
    version = "latest";
    src = firefox-src;

    # The copied binaries are already-fixed upstream artifacts. firefox-src is
    # the nixpkgs-built (and autoPatchelf'd) firefox-bin, so its binaries are
    # already correctly linked. stdenv's default fixupPhase would otherwise run
    # `patchelf --shrink-rpath` and `strip` over every ELF, which — like a
    # second autoPatchelfHook pass — corrupts the ~240 MB libxul.so and makes
    # Firefox segfault immediately on launch (a jump to a near-zero address).
    # Leave them byte-identical to upstream.
    dontPatchELF = true;
    dontStrip = true;

    unpackPhase = "true";

    installPhase = ''
runHook preInstall

# Create destination
LIB_DIR="$out/lib/firefox-nightly"
mkdir -p "$LIB_DIR"

# Upstream is now a (nixpkgs-wrapped) firefox-bin package: the real runtime
# app dir is $src/lib/firefox-bin-<version>/, containing the 'firefox'
# launcher, 'firefox-bin', and the browser/ tree. ($src/bin/firefox is only a
# small wrapper stub.) Many entries there are symlinks into the -unwrapped
# store path; cp -L dereferences them. Anchor on the (single) versioned dir
# via a glob — robust regardless of build-sandbox quirks, unlike find|head.
SRC_DIR=$(echo "$src"/lib/firefox-bin-*)
if [ ! -x "$SRC_DIR/firefox" ]; then
    echo "ERROR: firefox launcher not found at $SRC_DIR/firefox" >&2
    echo "Contents of $src/lib:" >&2
    ls -la "$src/lib" >&2 || true
    exit 1
fi

# Copy all files and ensure we have write permissions to modify/patch them
cp -L -r "$SRC_DIR"/* "$LIB_DIR/"
chmod -R +w "$LIB_DIR"

# Policies
mkdir -p "$LIB_DIR/distribution"
echo '${builtins.toJSON firefoxNightlyPolicies}' > "$LIB_DIR/distribution/policies.json"

# Desktop Item
mkdir -p "$out/share/applications"
cp ${firefoxNightlyDesktopItem}/share/applications/* "$out/share/applications/"

# Ensure the binary is executable for the wrapper
chmod +x "$LIB_DIR/firefox"

# Create the wrapper.
#
# $src/bin/firefox is the upstream nixpkgs wrapper: a shell script that sets up
# the full runtime environment (LD_LIBRARY_PATH for ffmpeg/libva/pulse/…,
# GTK_PATH, XDG_DATA_DIRS, GIO_EXTRA_MODULES, GDK_PIXBUF_MODULE_FILE, and
# crucially MOZ_LEGACY_PROFILES) before exec'ing the real launcher. We inherit
# that environment verbatim — replicating it by hand would hardcode store paths
# that drift every update — and only change the final exec to point at OUR
# copied launcher, which carries our distribution/policies.json. Our NVIDIA/
# Wayland vars are layered on just before the exec.
#
# Without this env the GTK chrome (Profile Manager, dialogs) renders blank for
# lack of icon loaders/theme, and MOZ_LEGACY_PROFILES being unset makes Firefox
# pick a per-install profile instead of the profiles.ini default.
mkdir -p "$out/bin"
WRAPPER="$out/bin/firefox-nightly"

# Everything except upstream's final `exec` line = the env setup we want.
grep -v '^exec ' "$src/bin/firefox" > "$WRAPPER"

cat >> "$WRAPPER" <<EOF
export MOZ_ENABLE_WAYLAND=1
export LIBVA_DRIVER_NAME=nvidia
export MOZ_DISABLE_RDD_SANDBOX=1
export NVD_BACKEND=direct
export __EGL_DISABLE_EXPLICIT_SYNC=1

[ -n "\$WAYLAND_DISPLAY" ] || export WAYLAND_DISPLAY=wayland-0
[ -n "\$DISPLAY" ] || export DISPLAY=:0
exec -a "\$0" "$LIB_DIR/firefox" "\$@"
EOF

chmod +x "$WRAPPER"

runHook postInstall
    '';

    meta = with lib; {
        description = "Firefox Nightly (Wrapped for NVIDIA/Wayland)";
        mainProgram = "firefox-nightly";
        platforms = platforms.linux;
    };
}

# <> #
