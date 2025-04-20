{ lib, stdenv, fetchFromGitHub, kdePackages, cmake, qt6 }:
stdenv.mkDerivation rec {
    pname = "darkly";
    version = "main";
    src = fetchFromGitHub {
        owner = "Bali10050";
        repo = "Darkly";
        rev = version;
        hash = "sha256-hT6OHL8xLp6PZba9hPDxvdGwNkf5ROH9L7ATtnuODpk=";
    };

    buildInputs = [
        kdePackages.frameworkintegration
        kdePackages.kcmutils
        kdePackages.kdecoration
        kdePackages.kirigami
        kdePackages.qtwayland
        qt6.full
    ];

    nativeBuildInputs = [
        cmake
        kdePackages.extra-cmake-modules
        kdePackages.wrapQtAppsHook
    ];

    cmakeFlags = [
        "-DCMAKE_INSTALL_PREFIX=$out"
        "-DCMAKE_BUILD_TYPE=Release"
        "-DBUILD_TESTING=OFF"
        "-DKDE_INSTALL_USE_QT_SYS_PATHS=ON"
        "-DBUILD_QT5=OFF"
    ];

    meta = {
        description = "Fork of breeze theme style that aims to be visually modern and minimalistic";
        homepage = "https://github.com/Bali10050/Darkly";
        changelog = "https://github.com/Bali10050/Darkly/commit/05a945c69f0dd4bec8fc32331ba4d85819af1fcb";
        license = with lib.licenses; [ bsd3 cc0 fdl12Plus gpl2Only gpl2Plus gpl3Only mit ];
    };
}
