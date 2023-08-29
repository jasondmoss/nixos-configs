{
  callPackage, lib, stdenv, fetchurl, fetchFromGitHub, cmake, pkg-config, git,
  qt6, alsa-lib, boost, chromaprint, fftw, gnutls, libcdio, libmtp, libXdmcp,
  libpthreadstubs, libtasn1, ninja, pcre, protobuf, sqlite, taglib, libgpod,
  libidn2, libsepol, p11-kit, libpulseaudio, libselinux, util-linux, libvlc,
  gst_all_1, glib-networking,
  qtx11extras ? null, withGstreamer ? true, withVlc ? true
}:
let
  inherit (lib) optionals;

  pname = "strawberry";
  version = "1.0.18";

  meta = with lib; {
    description = "Music player and music collection organizer";
    homepage = "https://www.strawberrymusicplayer.org/";
    changelog = "https://raw.githubusercontent.com/jonaski/strawberry/${version}/Changelog";
    license = licenses.gpl3Only;
    maintainers = with maintainers; [ peterhoeg ];
    # upstream says darwin should work but they lack maintainers as of 0.6.6
    platforms = platforms.linux;
  };

in stdenv.mkDerivation rec {
  pname = "strawberry";
  inherit version;
  inherit meta;

  src = fetchFromGitHub {
    owner = "jonaski";
    repo = pname;
    rev = version;
    hash = "sha256-vOay9xPSwgSYurFgL9f4OdBPzGJkV4t+7lJgeCeT0c4=";
  };

  # The big strawberry shown in the context menu is *very* much in your face,
  # so use the grey version instead
  postPatch = ''
    substituteInPlace src/context/contextalbum.cpp \
      --replace pictures/strawberry.png pictures/strawberry-grey.png
  '';

  buildInputs = [
    alsa-lib
    boost
    chromaprint
    fftw
    gnutls
    libcdio
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
