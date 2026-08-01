{
    lib, stdenv, fetchFromGitHub, unicode-emoji, unicode-character-database,
    unicode-idna, publicsuffix-list, chromium-hsts-preload-list, cmake, ninja,
    pkg-config, curlFull, libavif, angle, libjxl, libedit, libpulseaudio,
    libwebp, libxcrypt, mimalloc, openssl, perl, python3, qt6Packages, woff2,
    cargo, fast-float, ffmpeg, fmt, fontconfig, rustPlatform, rustc, simdutf,
    skia, nixosTests, unstableGitUpdater, libtommath, sdl3, icu78, simdjson,
    runCommand, harfbuzz, libxml2, sqlite, vulkan-memory-allocator, fetchgit
}:

let
    # Ladybird's GIFLoader includes wuffs' single-file amalgamation
    # <wuffs/wuffs-v0.3.c>. Upstream pulls it from vcpkg (overlay-port pins
    # google/wuffs-mirror-release-c v0.3.4); nixpkgs' `wuffs` package only
    # ships the compiler binary, so lay the header out on an include path here.
    wuffs-header = runCommand "wuffs-header-0.3.4" {
        src = fetchFromGitHub {
            owner = "google";
            repo = "wuffs-mirror-release-c";
            rev = "v0.3.4";
            hash = "sha256-V7inWJqH7Q4Ac/ZB//7XHrpgfAYUPBxWBerBem6Q/Kk=";
        };
    } ''
mkdir -p $out/include/wuffs
cp $src/release/c/wuffs-v0.3.c $out/include/wuffs/
    '';
in
stdenv.mkDerivation (finalAttrs: {
    pname = "ladybird";
    version = "master";

    src = fetchFromGitHub {
        owner = "LadybirdBrowser";
        repo = "ladybird";
        rev = "master";
        hash = "sha256-ImVHW4D7Fl3F5fgLBOzS2e5eCLOQznS1rpNXq8htvIg=";
    };

    cargoDeps = rustPlatform.fetchCargoVendor {
        inherit (finalAttrs) src;
        hash = "sha256-2asgV8IT3QKXvPezmP7VP+idLGDR/jfUa38/mErm7VI=";
    };

    postPatch = ''
sed -i '/iconutil/d' UI/CMakeLists.txt

# curl (glibc >= 2.42) issues readv/writev from RequestServer, but the seccomp
# network profile only allows read/write, so RequestServer is killed on the
# first fetch (SIGSYS -> "RequestServer is currently unavailable" -> IPC
# verification failure -> WebContent SIGILL). Allow the vectored equivalents.
# There is no IF_DEFINED_readv/writev macro, so use the base allow macro
# (readv/writev are always defined on Linux).
sed -i '/SECCOMP_APPEND_ALLOW_SYSCALL_IF_DEFINED(\*this, write);/a SECCOMP_APPEND_ALLOW_SYSCALL(*this, writev);' Libraries/LibSandbox/Seccomp.cpp
sed -i '/SECCOMP_APPEND_ALLOW_SYSCALL_IF_DEFINED(\*this, write);/a SECCOMP_APPEND_ALLOW_SYSCALL(*this, readv);' Libraries/LibSandbox/Seccomp.cpp

# RequestServer's Landlock sandbox grants read access to /etc/ssl only, but on
# NixOS /etc/ssl/certs/ca-certificates.crt is a symlink into /nix/store, and
# Landlock checks the resolved inode -> "SSL verification failed". Grant the
# (world-readable, immutable) store read-only so curl can read the CA bundle.
sed -i '\#add_landlock_path_if_exists(paths, "/etc/ssl"sv#a\    TRY(Sandbox::add_landlock_path_if_exists(paths, "/nix/store"sv, Sandbox::LandlockPath::Access::ReadOnly));' Services/RequestServer/SandboxLinux.cpp

perl -0pi -e \
  's/find_package\(ICU 78\.[0-9]+ EXACT REQUIRED COMPONENTS data i18n uc\)/find_package(ICU ${icu78.version} EXACT REQUIRED COMPONENTS data i18n uc)/ or die "ICU dependency not found\n"' \
  Meta/CMake/check_for_dependencies.cmake

# Don't set absolute paths in RPATH
substituteInPlace Meta/CMake/lagom_install_options.cmake\
 --replace-fail "\''${CMAKE_INSTALL_BINDIR}" "bin"\
 --replace-fail "\''${CMAKE_INSTALL_LIBDIR}" "lib"
    '';

    preConfigure = ''
# Setup caches for LibUnicode, LibTLS and LibGfx
# Note that the versions of the input data packages must match the
# expected version in the package's CMake.

mkdir -p build/Caches

cp -r ${unicode-character-database}/share/unicode build/Caches/UCD
chmod +w build/Caches/UCD
cp ${unicode-emoji}/share/unicode/emoji/emoji-test.txt build/Caches/UCD
cp ${unicode-idna}/share/unicode/idna/IdnaMappingTable.txt build/Caches/UCD
echo -n ${unicode-character-database.version} > build/Caches/UCD/version.txt
chmod -w build/Caches/UCD

mkdir build/Caches/PublicSuffix
cp ${publicsuffix-list}/share/publicsuffix/public_suffix_list.dat build/Caches/PublicSuffix

mkdir build/Caches/HSTSPreload
cp ${chromium-hsts-preload-list}/share/chromium-hsts-preload-list/transport_security_state_static.json build/Caches/HSTSPreload
    '';

    nativeBuildInputs = [
        cargo
        cmake
        ninja
        perl
        pkg-config
        python3
        rustPlatform.cargoSetupHook
        rustc
        qt6Packages.wrapQtAppsHook
        libtommath
    ];

    buildInputs = [
        curlFull
        fast-float
        ffmpeg
        fmt
        fontconfig
        harfbuzz
        libavif
        angle # libEGL
        libjxl
        libedit
        libwebp
        libxcrypt
        libxml2
        # Ladybird master pins mimalloc 2.2.7 (vcpkg); nixpkgs ships 3.x, which
        # renamed mi_heap_get_default (AK/kmalloc.cpp fails to compile against it).
        (mimalloc.overrideAttrs (o: {
            version = "2.2.7";
            src = fetchFromGitHub {
                owner = "microsoft";
                repo = "mimalloc";
                tag = "v2.2.7";
                hash = "sha256-z9qMOTcGkURblZChXDGfQ58hrql52lG6EE1NQmxxuj0=";
            };
        }))
        openssl
        sqlite
        vulkan-memory-allocator
        wuffs-header
        qt6Packages.qtbase
        qt6Packages.qtmultimedia
        sdl3
        simdutf
        (skia.overrideAttrs (prev: {
            # Ladybird master pins skia=148 exactly (pkg-config check); nixpkgs
            # ships m144. Bump to the chrome/m148 branch tip so the .pc reports 148.
            version = "148-unstable-2026-08-01";
            src = fetchgit {
                url = "https://skia.googlesource.com/skia.git";
                rev = "13ffba253fc7854fd3b34f67c82dfb2418dc2944";
                hash = "sha256-z85k29Yn7UOMUHtyDQ0lcUAMLLSSjEY0fBR6cO+jfYo=";
            };
            gnFlags = prev.gnFlags ++ [
                # https://github.com/LadybirdBrowser/ladybird/commit/af3d46dc06829dad65309306be5ea6fbc6a587ec
                # https://github.com/LadybirdBrowser/ladybird/commit/4d7b7178f9d50fff97101ea18277ebc9b60e2c7c
                # Remove when/if this gets upstreamed in skia.
                "extra_cflags+=[\"-DSKCMS_API=[[gnu::visibility(\\\"default\\\")]]\"]"
            ];
            # NB: the vcpkg skpath-enable-edit-methods.patch that nixpkgs' ladybird
            # applies is already upstreamed as of chrome/m148, so it is not applied
            # here (it fails as an already-applied/reversed patch on this branch).
        }))
        woff2
        icu78
        simdjson
    ]
    ++ lib.optionals stdenv.hostPlatform.isLinux [
        libpulseaudio.dev
        qt6Packages.qtwayland
    ];

    cmakeFlags = [
      # Takes an enormous amount of resources, even with mold
      (lib.cmakeBool "ENABLE_LTO_FOR_RELEASE" false)
      # Disable network operations
      "-DLADYBIRD_CACHE_DIR=Caches"
      "-DENABLE_NETWORK_DOWNLOADS=OFF"
      # Ladybird requires icu 78, but without this flag the default icu
      # from other dependencies gets picked up instead.
      (lib.cmakeFeature "ICU_ROOT" (toString icu78.dev))
    ]
    ++ lib.optionals stdenv.hostPlatform.isLinux [
        "-DCMAKE_INSTALL_LIBEXECDIR=libexec"
    ];

    # ld: [...]/OESVertexArrayObject.cpp.o: undefined reference to symbol 'glIsVertexArrayOES'
    # ld: [...]/libGL.so.1: error adding symbols: DSO missing from command line
    # https://github.com/LadybirdBrowser/ladybird/issues/371#issuecomment-2616415434
    env.NIX_LDFLAGS = "-lGL -lfontconfig";

    postInstall = lib.optionalString stdenv.hostPlatform.isDarwin ''
mkdir -p $out/Applications $out/bin
mv $out/bundle/Ladybird.app $out/Applications
    '';

    passthru.tests = {
        nixosTest = nixosTests.ladybird;
    };

    passthru.updateScript = unstableGitUpdater { };

    meta = with lib; {
        description = "Browser using the SerenityOS LibWeb engine with a Qt GUI";
        homepage = "https://ladybird.org";
        license = licenses.bsd2;
        maintainers = with maintainers; [fgaz];
        platforms = [ "x86_64-linux" ];
        mainProgram = "Ladybird";
    };
})

# <> #
