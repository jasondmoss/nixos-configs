{
    alsa-lib, boost, chromaprint, cmake, fetchFromGitHub, fftw, glib-networking,
    gnutls, gst_all_1, kdePackages, kdsingleapplication, lib, libXdmcp, libcdio,
    libebur128, libidn2, libmtp, libuchardet, libpthreadstubs, libpulseaudio, libsecret, libselinux,
    libsepol, libtasn1, ninja, nix-update-script, p11-kit, pkg-config,
    rapidjson, sparsehash, sqlite, stdenv, taglib, util-linux
}:

let
    inherit (lib) optionals;

    ## Tracks upstream `master`, pinned to a commit. Everything in
    ## manifest.json comes from ./update.sh (run by nxmanifest before every
    ## nxup): the commit, its date, its fetchFromGitHub hash and the
    ## `<date>.<rev>` version.
    manifest = lib.importJSON ./manifest.json;
in
stdenv.mkDerivation rec {
    pname = "strawberry";
    inherit (manifest) version;

    src = fetchFromGitHub {
        owner = "strawberrymusicplayer";
        repo = pname;
        inherit (manifest) rev hash;
    };

    # The big strawberry shown in the context menu is *very* much in your face,
    # so use the grey version instead. --replace-fail, so a bump that moves
    # the image fails verify.nix instead of silently dropping the swap.
    postPatch = ''
substituteInPlace src/context/contextalbum.cpp \
 --replace-fail pictures/strawberry.png pictures/strawberry-grey.png
    '';

    buildInputs = [
        alsa-lib
        boost
        chromaprint
        fftw
        gnutls
        kdsingleapplication
        libXdmcp
        libcdio
        libebur128
        libidn2
        libmtp
        libpthreadstubs
        libtasn1
        libuchardet
        kdePackages.layer-shell-qt # "OSD Pretty" on Wayland (required since 2026-10 master)
        kdePackages.qtbase
        rapidjson
        sparsehash
        sqlite
        taglib
    ] ++ optionals stdenv.hostPlatform.isLinux [
        libpulseaudio
        libsecret
        libselinux
        libsepol
        p11-kit
    ] ++ (with gst_all_1; [
        glib-networking
        gst-libav
        gst-plugins-bad
        gst-plugins-base
        gst-plugins-good
        gst-plugins-ugly
        gstreamer
    ]);

    nativeBuildInputs = [
        cmake
        ninja
        pkg-config
        kdePackages.qttools
        kdePackages.wrapQtAppsHook
    ] ++ optionals stdenv.hostPlatform.isLinux [
        util-linux
    ];

    cmakeFlags = [
        "-DENABLE_GPOD=OFF" # `libgpod` is dead
    ];

    postInstall = ''
qtWrapperArgs+=(
    --prefix GST_PLUGIN_SYSTEM_PATH_1_0 : "$GST_PLUGIN_SYSTEM_PATH_1_0"
    --prefix GIO_EXTRA_MODULES : "${glib-networking.out}/lib/gio/modules"
)
    '';

    passthru.updateScript = nix-update-script { };

    meta = with lib; {
        description = "Music player and music collection organizer";
        homepage = "https://www.strawberrymusicplayer.org/";
        changelog = "https://raw.githubusercontent.com/strawberrymusicplayer/strawberry/${manifest.rev}/Changelog";
        license = licenses.gpl3Only;
        maintainers = with maintainers; [ peterhoeg ];
        platforms = platforms.linux;
        mainProgram = "strawberry";
    };
}

# <> #
