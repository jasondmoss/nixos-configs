{ lib
, stdenv
, cmake
, extra-cmake-modules
, qt6
, kdePackages
, wayland
, wayland-scanner
}:

stdenv.mkDerivation {
  pname   = "plasma-dock";
  version = "0.1.0";

  src = lib.cleanSource ./..;

  nativeBuildInputs = [
    cmake
    extra-cmake-modules
    qt6.wrapQtAppsHook
    wayland-scanner
  ];

  buildInputs = [
    qt6.qtbase
    qt6.qtdeclarative        # QtQuick / QML
    qt6.qtwayland            # QtWaylandClient + private headers
    kdePackages.kwindowsystem
    kdePackages.kservice
    kdePackages.kconfig
    kdePackages.layer-shell-qt
    wayland
  ];

  cmakeFlags = [
    "-DCMAKE_BUILD_TYPE=Release"
  ];

  meta = {
    description = "A custom KDE Plasma dock using layer-shell";
    license     = lib.licenses.gpl3Plus;
    platforms   = lib.platforms.linux;
    mainProgram = "plasma-dock";
  };
}
