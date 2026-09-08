{ lib, stdenv, kdePackages, cmake, libepoxy, libdrm, vulkan-headers, wayland }:

stdenv.mkDerivation {
    pname = "stage-manager";
    version = "0.1.0";

    # Local workshop project — MacOS Stage Manager clone.
    src = lib.cleanSourceWith {
        filter = name: type: baseNameOf name != "build";
        src = lib.cleanSource ../../workshop/stage-manager;
    };

    buildInputs = [
        kdePackages.kwin
        kdePackages.qtbase
        kdePackages.kcmutils
        kdePackages.kconfig
        kdePackages.kcoreaddons
        kdePackages.ki18n
        kdePackages.kwindowsystem
        kdePackages.kguiaddons
        kdePackages.kglobalaccel
        kdePackages.kxmlgui
        libepoxy
        libdrm
        vulkan-headers
        wayland
    ];

    nativeBuildInputs = [
        cmake
        kdePackages.extra-cmake-modules
        kdePackages.wrapQtAppsHook
    ];

    cmakeFlags = [
        "-DCMAKE_BUILD_TYPE=Release"
        "-DKDE_INSTALL_USE_QT_SYS_PATHS=ON"
    ];

    meta = {
        description = "KWin effect: windows shrink along a warp curve toward the screen edges and park there (Desktop5 spatial desktop concept)";
        homepage = "https://github.com/scottjenson/Desktop5";
        license = lib.licenses.gpl2Plus;
        platforms = lib.platforms.linux;
    };
}

# <> #
