{ lib, stdenv, fetchFromGitHub, kdePackages, cmake }:

let
    ## Tracks upstream `main`, pinned to a commit. Everything in manifest.json
    ## comes from ./update.sh (run by nxmanifest before every nxup): the
    ## commit, its date, its fetchFromGitHub hash and the `<date>.<rev>`
    ## version.
    manifest = lib.importJSON ./manifest.json;
in
stdenv.mkDerivation rec {
    pname = "darkly";
    inherit (manifest) version;

    src = fetchFromGitHub {
        owner = "Bali10050";
        repo = "Darkly";
        inherit (manifest) rev hash;
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
        changelog = "https://github.com/Bali10050/Darkly/commits/${manifest.rev}";
        license = with lib.licenses; [ bsd3 cc0 fdl12Plus gpl2Only gpl2Plus gpl3Only mit ];
    };
}

# <> #
