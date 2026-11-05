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

    # QML disk cache — left ON (2026-11-05). Krema's QML is a plain qrc
    # (qt_add_resources, no qmlcachegen), compiled at runtime into
    # ~/.cache/krema/qmlcache. This used to be `--set QML_DISABLE_DISK_CACHE 1`,
    # because the cache was validated by source time stamp and under Nix every
    # build embeds the same one (rcc uses SOURCE_DATE_EPOCH), so a rebuild of
    # this patched package kept running the old compiled QML. Qt 6.12.0 saves
    # every cache unit in content-hash mode instead (MD5 of the QML source,
    # re-checked on load — qtdeclarative src/qml/common/qv4compileddata.cpp,
    # verified against the 6.12.0 source), so a changed patch recompiles.
    #
    # The --set was also inherited by every app launched from the dock: it
    # switched the QML cache off for all of them and broke apps that ship
    # AOT-compiled QML with the qrc sources stripped (Clate — every panel
    # failed with "Expected token `numeric literal'"). Only re-applied on a Qt
    # older than the version checked above.
    qtWrapperArgs = lib.optionals (lib.versionOlder qtdeclarative.version "6.12") [
        "--set QML_DISABLE_DISK_CACHE 1"
    ];

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
