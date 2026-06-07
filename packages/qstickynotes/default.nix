{ lib, stdenv, fetchFromGitHub, cmake, qt6 }:

stdenv.mkDerivation (finalAttrs: {
    pname = "qstickynotes";
    version = "0-unstable-2026-06-06";

    src = fetchFromGitHub {
        owner = "ivnish";
        repo = "QStickyNotes";
        rev = "f41ef73b1bfd9e3a203185446ff94394673321d1";
        hash = "sha256-3crYQyptFp9H6nuS/uTHe3gfBuzjXjquWofWxepkeUg=";
    };

    nativeBuildInputs = [
        cmake
        qt6.wrapQtAppsHook
    ];

    buildInputs = [
        qt6.qtbase
        qt6.qtwayland
    ];

    meta = {
        description = "Lightweight sticky notes application built with Qt";
        homepage = "https://github.com/ivnish/QStickyNotes";
        license = lib.licenses.gpl3Only;
        mainProgram = "QStickyNotes";
        platforms = lib.platforms.linux;
    };
})

# <> #
