{
    alsa-lib,
    boost,
    chromaprint,
    cmake,
    fetchFromGitHub,
    fftw,
    glib-networking,
    gnutls,
    gst_all_1,
    kdsingleapplication,
    lib,
    libXdmcp,
    libcdio,
    libebur128,
    libgpod,
    libidn2,
    libmtp,
    libpthreadstubs,
    libpulseaudio,
    libselinux,
    libsepol,
    libtasn1,
    ninja,
    nix-update-script,
    p11-kit,
    pkg-config,
    qt6,
    sqlite,
    stdenv,
    taglib,
    util-linux
}:
let
    inherit (lib) optionals;

    pname = "strawberry";
    version = "master";

    src = fetchFromGitHub {
        owner = "jonaski";
        repo = pname;
        rev = version;
        hash = "sha256-3lfxRsQeMjvsLjboFlSsC7gOoCpu6UZjVrzg777My/w=";
    };

    meta = with lib; {
        description = "Music player and music collection organizer";
        homepage = "https://www.strawberrymusicplayer.org/";
        changelog = "https://raw.githubusercontent.com/jonaski/strawberry/${version}/Changelog";
        license = licenses.gpl3Only;
        maintainers = with maintainers; [ peterhoeg ];
        platforms = platforms.linux;
        mainProgram = "strawberry";
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
        libXdmcp
        libcdio
        libebur128
        libidn2
        libmtp
        libpthreadstubs
        libtasn1
        qt6.qtbase
        sqlite
        taglib
    ] ++ optionals stdenv.hostPlatform.isLinux [
        libgpod
        libpulseaudio
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
        qt6.qttools
        qt6.wrapQtAppsHook
    ] ++ optionals stdenv.hostPlatform.isLinux [
        util-linux
    ];

    postInstall = ''
qtWrapperArgs+=(
    --prefix GST_PLUGIN_SYSTEM_PATH_1_0 : "$GST_PLUGIN_SYSTEM_PATH_1_0"
    --prefix GIO_EXTRA_MODULES : "${glib-networking.out}/lib/gio/modules"
)
    '';

    passthru.updateScript = nix-update-script { };
}
