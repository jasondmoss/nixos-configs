{ lib, stdenv, fetchFromGitHub, kdePackages, cmake, python3, xcursorgen }:

stdenv.mkDerivation rec {
    pname = "vinyl";
    version = "6.6.3-unstable-2026-07-01";

    src = fetchFromGitHub {
        owner = "ekaaty";
        repo = "vinyl-theme";
        rev = "8358bf1639e897d266c479240ac7994a1ee8e2c0";
        hash = "sha256-QbivipDNLrdllF8ebC0ix+5vtKkvdnrqC0zsphrWSXQ=";
    };

    buildInputs = [
        kdePackages.frameworkintegration
        kdePackages.kcmutils
        kdePackages.kcolorscheme
        kdePackages.kconfig
        kdePackages.kcoreaddons
        kdePackages.kdecoration
        kdePackages.kguiaddons
        kdePackages.ki18n
        kdePackages.kiconthemes
        kdePackages.kirigami
        kdePackages.kwindowsystem
        kdePackages.libplasma
        kdePackages.qtdeclarative
        kdePackages.qtsvg
        kdePackages.qtwayland
    ];

    nativeBuildInputs = [
        cmake
        kdePackages.extra-cmake-modules
        kdePackages.wrapQtAppsHook
        (python3.withPackages (p: with p; [ cairosvg lxml ]))
        xcursorgen
    ];

    # The cursor pipeline runs svgslice.py via /usr/bin/env, which
    # does not exist in the build sandbox.
    postPatch = ''
        patchShebangs cursors/svgslice.py
    '';

    # Upstream icon themes ship symlinks whose targets are not installed
    # (e.g. start-here-kde-plasma.svg), which trips noBrokenSymlinks.
    postInstall = ''
        find $out/share/icons -xtype l -delete
    '';

    cmakeFlags = [
        "-DCMAKE_BUILD_TYPE=Release"
        "-DBUILD_TESTING=OFF"
        "-DKDE_INSTALL_USE_QT_SYS_PATHS=ON"
    ];

    meta = {
        description = "A theme suite for KDE Plasma (application style, decorations, plasma/global themes, icons, cursors, SDDM, splash)";
        homepage = "https://github.com/ekaaty/vinyl-theme";
        changelog = "https://github.com/ekaaty/vinyl-theme/commits/main";
        license = with lib.licenses; [ bsd3 cc0 gpl2Only gpl2Plus gpl3Only lgpl21Plus mit ];
    };
}

# <> #
