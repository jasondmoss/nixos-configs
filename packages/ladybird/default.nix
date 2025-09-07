{
    lib, stdenv, fetchFromGitHub, fetchurl, cacert, unicode-emoji,
    unicode-character-database, unicode-idna, publicsuffix-list, cmake,
    copyDesktopItems, makeDesktopItem, ninja, pkg-config, curl, lcms, libavif,
    libGL, libjxl, libpulseaudio, libwebp, libxcrypt, openssl, python3,
    qt6Packages, woff2, ffmpeg, fontconfig, simdutf, skia, nixosTests,
    unstableGitUpdater, apple-sdk_14, libtommath
}: let

    adobe-icc-profiles = fetchurl {
        url = "https://download.adobe.com/pub/adobe/iccprofiles/win/AdobeICCProfilesCS4Win_end-user.zip";
        hash = "sha256-kgQ7fDyloloPaXXQzcV9tgpn3Lnr37FbFiZzEb61j5Q=";
        name = "adobe-icc-profiles.zip";
    };
    cacert_version = "2025-05-20";

in stdenv.mkDerivation (finalAttrs: {

    pname = "ladybird";
#        version = "master";
    version = "0-unstable-2025-06-27";

    src = fetchFromGitHub {
        owner = "LadybirdBrowser";
        repo = "ladybird";
        rev = "831ba5d6550fd9dfaf90153876ff42396f7165ac";
        hash = "sha256-7feXPFKExjuOGbitlAkSEEzYNEZb6hGSDUZW1EJGIW8=";
#            rev = "master";
#            hash = "sha256-Wzv+cS3j3yzs373bcOSsxhcX2QcbamkgLUlLhQ1GE/E=";
    };

#        patches = [
#            # Revert https://github.com/LadybirdBrowser/ladybird/commit/51d189198d3fc61141fc367dc315c7f50492a57e
#            # This commit doesn't update the skia used by ladybird vcpkg, but it does update the skia that
#            # that cmake wants.
#            ./001-revert-fake-skia-update.patch
#        ];

    postPatch = ''
sed -i '/iconutil/d' UI/CMakeLists.txt

# Don't set absolute paths in RPATH
substituteInPlace Meta/CMake/lagom_install_options.cmake\
 --replace-fail "\''${CMAKE_INSTALL_BINDIR}" "bin"\
 --replace-fail "\''${CMAKE_INSTALL_LIBDIR}" "lib"
    '';

    preConfigure = ''
# Setup caches for LibUnicode, LibTLS and LibGfx
# Note that the versions of the input data packages must match the
# expected version in the package's CMake.

# Check that the versions match
grep -F 'set(CACERT_VERSION "${cacert_version}")' Meta/CMake/ca_certificates_data.cmake || (echo cacert_version mismatch && exit 1)

mkdir -p build/Caches

cp -r ${unicode-character-database}/share/unicode build/Caches/UCD
chmod +w build/Caches/UCD
cp ${unicode-emoji}/share/unicode/emoji/emoji-test.txt build/Caches/UCD
cp ${unicode-idna}/share/unicode/idna/IdnaMappingTable.txt build/Caches/UCD
echo -n ${unicode-character-database.version} > build/Caches/UCD/version.txt
chmod -w build/Caches/UCD

mkdir build/Caches/CACERT
cp ${cacert}/etc/ssl/certs/ca-bundle.crt build/Caches/CACERT/cacert-${cacert_version}.pem
echo -n ${cacert_version} > build/Caches/CACERT/version.txt

mkdir build/Caches/PublicSuffix
cp ${publicsuffix-list}/share/publicsuffix/public_suffix_list.dat build/Caches/PublicSuffix

mkdir build/Caches/AdobeICCProfiles
cp ${adobe-icc-profiles} build/Caches/AdobeICCProfiles/adobe-icc-profiles.zip
chmod +w build/Caches/AdobeICCProfiles
    '';

    nativeBuildInputs = [
        cmake
        copyDesktopItems
        ninja
        pkg-config
        python3
        qt6Packages.wrapQtAppsHook
        libtommath
    ];

    buildInputs = [
        curl
        ffmpeg
        fontconfig
        libavif
        libGL
        libjxl
        libwebp
        libxcrypt
        lcms
        openssl
        libpulseaudio.dev
        qt6Packages.qtbase
        qt6Packages.qtmultimedia
        qt6Packages.qtwayland
        simdutf
        (skia.overrideAttrs (prev: {
            gnFlags = prev.gnFlags ++ [
                # https://github.com/LadybirdBrowser/ladybird/commit/af3d46dc06829dad65309306be5ea6fbc6a587ec
                # https://github.com/LadybirdBrowser/ladybird/commit/4d7b7178f9d50fff97101ea18277ebc9b60e2c7c
                # Remove when/if this gets upstreamed in skia.
                "extra_cflags+=[\"-DSKCMS_API=__attribute__((visibility(\\\"default\\\")))\"]"
            ];
        }))
        woff2
    ];

    cmakeFlags = [
      # Takes an enormous amount of resources, even with mold
      (lib.cmakeBool "ENABLE_LTO_FOR_RELEASE" false)
      # Disable network operations
      "-DSERENITY_CACHE_DIR=Caches"
      "-DENABLE_NETWORK_DOWNLOADS=OFF"
      "-DCMAKE_INSTALL_LIBEXECDIR=libexec"
    ];

    # ld: [...]/OESVertexArrayObject.cpp.o: undefined reference to symbol 'glIsVertexArrayOES'
    # ld: [...]/libGL.so.1: error adding symbols: DSO missing from command line
    # https://github.com/LadybirdBrowser/ladybird/issues/371#issuecomment-2616415434
    env.NIX_LDFLAGS = "-lGL -lfontconfig";

    postInstall = ''
for size in 48x48 128x128; do
mkdir -p $out/share/icons/hicolor/$size/apps
ln -s $out/share/Lagom/icons/$size/app-browser.png \
$out/share/icons/hicolor/$size/apps/ladybird.png
done
    '' + lib.optionalString stdenv.hostPlatform.isDarwin ''
mkdir -p $out/Applications $out/bin
mv $out/bundle/Ladybird.app $out/Applications
    '';

    desktopItems = [
        (makeDesktopItem {
            name = "ladybird";
            desktopName = "Ladybird";
            exec = "Ladybird -- %U";
            icon = "ladybird";
            categories = [
                "Network"
                "WebBrowser"
            ];
            mimeTypes = [
                "text/html"
                "application/xhtml+xml"
                "x-scheme-handler/http"
                "x-scheme-handler/https"
            ];
            actions.new-window = {
                name = "New Window";
                exec = "Ladybird --new-window -- %U";
            };
        })
    ];

    passthru.tests = {
        nixosTest = nixosTests.ladybird;
    };

    passthru.updateScript = unstableGitUpdater { };

    meta = with lib; {
        description = "Browser using the SerenityOS LibWeb engine with a Qt";
        homepage = "https://ladybird.org";
        license = licenses.bsd2;
        maintainers = with maintainers; [fgaz];
        platforms = [ "x86_64-linux" ];
        mainProgram = "Ladybird";
    };
})
