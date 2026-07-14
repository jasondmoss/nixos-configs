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
