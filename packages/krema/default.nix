{
    lib, stdenv, fetchFromGitHub,
    cmake, extra-cmake-modules, ninja, pkg-config, wrapQtAppsHook, spirv-tools,
    qtbase, qtdeclarative, qtshadertools,
    kconfig, kcoreaddons, kdbusaddons, ki18n, kglobalaccel, kcolorscheme,
    kiconthemes, kcrash, kxmlgui, kservice, kwindowsystem,
    kirigami, kirigami-addons, layer-shell-qt, plasma-workspace, kpipewire,
    wayland, wayland-protocols,
}:

stdenv.mkDerivation (finalAttrs: {
    pname = "krema";
    version = "0.7.0";

    src = fetchFromGitHub {
        owner = "isac322";
        repo  = "krema";
        tag   = "v${finalAttrs.version}";
        hash  = "sha256-ppAUIUIR0mlUd8BbyNLvXuVAVq0+otSMjS32v/+Ftx0=";
    };

    # Upstream bugs (unreported as of v0.7.0):
    #  0001 — updateHoveredItem() in main.qml hard-codes horizontal-dock axes for
    #         its hit-test bounds checks, so on a vertical (left/right) dock only
    #         the first icon is ever clickable/hoverable. Also keeps the strip
    #         between the icons and the screen edge claimable on every edge
    #         (edge-slammed clicks previously fell in a ~4px dead zone).
    #  0002 — vertical docks size the surface cross-axis with the horizontal
    #         tooltip reserve (36px), clipping tooltips at the surface edge;
    #         reserve enough width for label text instead.
    #  0003 — DodgeWindows: the overlap-detection rect only anchors Y while the
    #         dock hides (m_panelRefY). Vertical docks slide along X, so the
    #         rect chased the panel off-screen → overlap vanished → dock came
    #         back → infinite hide/show oscillation. Anchor X the same way.
    # Remove once fixed upstream.
    patches = [
        ./patches/0001-fix-vertical-dock-hit-testing.patch
        ./patches/0002-vertical-dock-tooltip-reserve.patch
        ./patches/0003-vertical-dock-dodge-ref-position.patch
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
