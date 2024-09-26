{
    lib, stdenv, autoconf, automake, c-ares, cryptopp, curl, doxygen,
    fetchFromGitHub, ffmpeg, libmediainfo, libraw, libsodium, libtool, libuv,
    libzen, lsb-release, pkg-config, qt5, sqlite, swig, unzip, wget
}:
let
    pname = "megasync";
    version = "5.4.1.0";
in
stdenv.mkDerivation rec {
    src = fetchFromGitHub {
        owner = "meganz";
        repo = "MEGAsync";
        rev = "v${version}_Linux";
        hash = "sha256-Y1nfY5iP64iSCYwzqxbjZAQNHyj4yVbSudSInm+yJzY=";
        fetchSubmodules = true;
    };

    nativeBuildInputs = [
        autoconf
        automake
        doxygen
        libtool
        lsb-release
        pkg-config
        qt5.qttools
        swig
        unzip
    ];

    buildInputs = [
        c-ares
        cryptopp
        curl
        ffmpeg
        libmediainfo
        libraw
        libsodium
        libuv
        libzen
        qt5.qtbase
        qt5.qtx11extras
        sqlite
        wget
    ];

    patches = [
# Distro and version targets attempt to use lsb_release which is broken
# (see issue: https://github.com/NixOS/nixpkgs/issues/22729)
./noinstall-distro-version.patch
# megasync target is not part of the install rule thanks to a commented block
./install-megasync.patch
    ];

    postPatch = ''
for file in $(find src/ -type f \( -iname configure -o -iname \*.sh \) ); do
    substituteInPlace "$file" --replace "/bin/bash" "${stdenv.shell}"
done
    '';

    dontUseQmakeConfigure = true;
    enableParallelBuilding = true;

    preConfigure = ''
cd src/MEGASync/mega
./autogen.sh
    '';

    configureFlags = [
        "--disable-examples"
        "--disable-java"
        "--disable-php"
        "--enable-chat"
        "--with-cares"
        "--with-cryptopp"
        "--with-curl"
        "--with-ffmpeg"
        "--without-freeimage"
        "--without-readline"
        "--without-termcap"
        "--with-sodium"
        "--with-sqlite"
        "--with-zlib"
    ];

    postConfigure = ''
cd ../..
    '';

    preBuild = ''
qmake CONFIG+="nofreeimage release" MEGA.pro
pushd MEGASync
    lrelease MEGASync.pro
    DESKTOP_DESTDIR="$out" qmake PREFIX="$out" -o Makefile MEGASync.pro CONFIG+="nofreeimage release"
popd
    '';

    meta = with lib; {
        description = "Easy automated syncing between your computers and your MEGA Cloud Drive";
        homepage = "https://mega.nz/";
        license = licenses.unfree;
        platforms = [ "i686-linux" "x86_64-linux" ];
        maintainers = [ ];
    };
}
