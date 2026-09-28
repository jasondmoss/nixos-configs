{
    lib, stdenv, fetchFromGitHub, cmake, extra-cmake-modules, ninja, pkg-config,
    wrapQtAppsHook, spirv-tools, qtbase, qtdeclarative, qtshadertools, kconfig,
    kcoreaddons, kdbusaddons, ki18n, kglobalaccel, kcolorscheme, kiconthemes,
    kcrash, kxmlgui, kservice, kwindowsystem, kirigami, kirigami-addons,
    layer-shell-qt, plasma-workspace, kpipewire, wayland, wayland-protocols,
}:

let
    ## Upstream release tags on GitHub. Version + hash come from manifest.json
    ## — refresh it with ./update.sh (same workflow as packages/claude-desktop
    ## and packages/vivaldi-snapshot), then rebuild. update.sh dry-runs the
    ## patches below against each candidate tag and refuses to bump past a tag
    ## they no longer apply to.
    manifest = lib.importJSON ./manifest.json;
in stdenv.mkDerivation (finalAttrs: {
    pname = "krema";

    inherit (manifest) version;

    src = fetchFromGitHub {
        owner = "isac322";
        repo  = "krema";
        tag   = "v${finalAttrs.version}";
        inherit (manifest) hash;
    };

    # Upstream bugs (unreported as of v0.9.0; v0.9.0 fixed the vertical-dock
    # hit-test axes and side-tooltip clipping that earlier patches carried):
    #  0001 — updateHoveredItem() in main.qml bounds both sides of the icon on
    #         the cross axis, so the strip between the icons and the screen
    #         edge (panel padding, ~8px) is a dead zone and edge-slammed clicks
    #         miss. Leave the screen-edge side unbounded on every edge.
    #  0002 — DodgeWindows: the overlap-detection rect only anchors Y while the
    #         dock hides (m_panelRefY). Vertical docks slide along X, so the
    #         rect chased the panel off-screen → overlap vanished → dock came
    #         back → infinite hide/show oscillation. Anchor X the same way.
    # Remove once fixed upstream.
    patches = [
        ./patches/0001-dock-edge-strip-hit-testing.patch
        ./patches/0002-vertical-dock-dodge-ref-position.patch
    ];

    # Qt's QML disk cache can serve stale compiled QML from ~/.cache/krema/qmlcache
    # across rebuilds of this patched package (qrc URL + timestamps don't change under
    # Nix), silently masking patch changes. Startup recompile cost is negligible.
    qtWrapperArgs = [ "--set QML_DISABLE_DISK_CACHE 1" ];

    nativeBuildInputs = [
        cmake
        extra-cmake-modules
        ninja
        pkg-config
        wrapQtAppsHook
        spirv-tools
    ];

    buildInputs = [
        qtbase
        qtdeclarative
        qtshadertools

        kconfig
        kcoreaddons
        kdbusaddons
        ki18n
        kglobalaccel
        kcolorscheme
        kiconthemes
        kcrash
        kxmlgui
        kservice
        kwindowsystem

        kirigami
        kirigami-addons
        layer-shell-qt
        plasma-workspace  # provides LibTaskManager / LibNotificationManager cmake configs
        kpipewire

        wayland
        wayland-protocols
    ];

    cmakeFlags = [
        (lib.cmakeBool "BUILD_TESTING" false)
    ];

    meta = {
        description = "Lightweight, high-performance dock for KDE Plasma 6, spiritual successor to Latte Dock";
        longDescription = ''
Krema is a native KDE Plasma 6 dock built with Qt 6 and KDE Frameworks 6.
It provides macOS-style parabolic zoom animations, live window previews via
PipeWire, and native Wayland layer-shell integration.
        '';
        homepage   = "https://github.com/isac322/krema";
        changelog  = "https://github.com/isac322/krema/releases/tag/v${finalAttrs.version}";
        license    = lib.licenses.gpl3Plus;
        platforms  = lib.platforms.linux;
        mainProgram = "krema";
    };
})

# <> #
