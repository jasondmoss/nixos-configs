{
    lib, stdenv, fetchFromGitHub, cmake, pkg-config, qt6, alsa-lib, boost,
    chromaprint, fftw, gnutls, libcdio, libmtp, libXdmcp, libpthreadstubs,
    libtasn1, ninja, pcre, protobuf, sqlite, taglib, libebur128, libgpod,
    libidn2, libsepol, p11-kit, libpulseaudio, libselinux, util-linux, libvlc,
    gst_all_1, glib-networking, kdsingleapplication,
    qtx11extras ? null,
    withGstreamer ? true,
    withVlc ? true
}:
let
    inherit (lib) optionals;

    pname = "strawberry";
    version = "master";

    src = fetchFromGitHub {
        owner = "jonaski";
        repo = pname;
        rev = version;
        hash = "sha256-JJybRqYJRpGaL2Q42URe6kzNy63HYjOVh0HRE+cxcL8=";
    };

    meta = with lib; {
        description = "Music player and music collection organizer";
        homepage = "https://www.strawberrymusicplayer.org/";
        changelog = "https://raw.githubusercontent.com/jonaski/strawberry/${version}/Changelog";
        license = licenses.gpl3Only;
        # upstream says darwin should work but they lack maintainers as of 0.6.6
        maintainers = with maintainers; [ peterhoeg ];
        platforms = platforms.linux;
    };
in stdenv.mkDerivation rec {
    pname = "strawberry";
    inherit version;
    inherit meta;
    inherit src;

    # The big strawberry shown in the context menu is *very* much in your face,
    # so use the grey version instead
    postPatch = ''
substituteInPlace src/context/contextalbum.cpp --replace pictures/strawberry.png pictures/strawberry-grey.png
    '';

    buildInputs = [
        alsa-lib
        boost
        chromaprint
        fftw
        gnutls
        kdsingleapplication
        libcdio
        libebur128
        libidn2
        libmtp
        libpthreadstubs
        libtasn1
        libXdmcp
        pcre
        protobuf
        sqlite
        taglib
        qt6.qtbase
        qtx11extras
    ] ++ optionals stdenv.isLinux [
        libgpod
        libpulseaudio
        libselinux
        libsepol
        p11-kit
    ] ++ optionals withGstreamer (with gst_all_1; [
        glib-networking
        gstreamer
        gst-libav
        gst-plugins-base
        gst-plugins-good
        gst-plugins-bad
        gst-plugins-ugly
    ]) ++ lib.optional withVlc libvlc;

    nativeBuildInputs = [
        cmake
        ninja
        pkg-config
        qt6.qttools
        qt6.wrapQtAppsHook
    ] ++ optionals stdenv.isLinux [
        util-linux
    ];

    preCheck = ''
    '';

    postInstall = lib.optionalString withGstreamer ''
qtWrapperArgs+=(
    --prefix GST_PLUGIN_SYSTEM_PATH_1_0 : "$GST_PLUGIN_SYSTEM_PATH_1_0"
    --prefix GIO_EXTRA_MODULES : "${glib-networking.out}/lib/gio/modules"
)
    '';
}
