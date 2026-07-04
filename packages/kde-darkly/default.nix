{ lib, stdenv, fetchFromGitHub, kdePackages, cmake }:

stdenv.mkDerivation rec {
    pname = "darkly";
    version = "main";

    src = fetchFromGitHub {
        owner = "Bali10050";
        repo = "Darkly";
        rev = version;
        hash = "sha256-u12imjPk4ZhOen/PgnLiNPML+5NmuKO0Ja4wQKU/Y8E=";
    };

    buildInputs = [
        kdePackages.frameworkintegration
        kdePackages.kcmutils
        kdePackages.kdecoration
        kdePackages.kirigami
        kdePackages.qtwayland
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
        changelog = "https://github.com/Bali10050/Darkly/commit/11c27e2d98025f4d4c1598f07a185280b36f35f7";
        license = with lib.licenses; [ bsd3 cc0 fdl12Plus gpl2Only gpl2Plus gpl3Only mit ];
    };
}

# <> #
