{ lib, stdenv, fetchFromGitHub, kdePackages, cmake }:

let
    ## Tracks upstream `master`, pinned to a commit. Everything in
    ## manifest.json comes from ./update.sh (run by nxmanifest before every
    ## nxup): the commit, its date, its fetchFromGitHub hash and the
    ## `<date>.<rev>` version.
    manifest = lib.importJSON ./manifest.json;
in
stdenv.mkDerivation rec {
    pname = "klassy";
    inherit (manifest) version;

    src = fetchFromGitHub {
        owner = "paulmcauley";
        repo = "klassy";
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
        description = "A highly customizable binary Window Decoration and Application Style plugin for recent versions of the KDE Plasma desktop";
        homepage = "https://github.com/paulmcauley/klassy";
        changelog = "https://github.com/paulmcauley/klassy/commits/${manifest.rev}";
        license = with lib.licenses; [ bsd3 cc0 fdl12Plus gpl2Only gpl2Plus gpl3Only mit ];
    };
}

# <> #
