{
    lib, stdenv, fetchurl, dpkg, autoPatchelfHook, patchelfUnstable, makeWrapper, addDriverRunpath,
    zlib, libgpg-error, gmp, e2fsprogs, fontconfig, freetype, libglvnd, xorg,
}:

let
    version = "2.2.0";

    src = fetchurl {
        url = "https://cdn.jopdf.com/download/jopdf/jopdf-linux-amd64_setup.deb";
        sha256 = "sha256-G993GJOUOh6WsbXcxir1MKrsUFmqCfqA4BtuAyKMsyc=";
    };

    ## Bundled Qt5 platform plugin needs GLX/EGL dispatch libs; the NVIDIA
    ## vendor driver itself is resolved at runtime via addDriverRunpath.
    gpuLibPath = lib.makeLibraryPath [ libglvnd ] + ":${addDriverRunpath.driverLink}/lib";
in stdenv.mkDerivation {
    pname = "jopdf";
    inherit version src;

    ## patchelf 0.15 (the default in this stdenv) fails on JOPDF's main binary
    ## with "cannot normalize PT_NOTE segment: non-contiguous SHT_NOTE sections";
    ## patchelfUnstable (0.18) handles it, so put it first on PATH.
    nativeBuildInputs = [ patchelfUnstable dpkg autoPatchelfHook makeWrapper ];

    ## JOPDF ships its own Qt5, ICU, OpenSSL, etc. under opt/jopdf/lib —
    ## only libraries missing from that bundle are listed here.
    buildInputs = [
        (lib.getLib stdenv.cc.cc)
        zlib
        libgpg-error
        gmp
        e2fsprogs.out # libcom_err.so.2, wanted by the bundled libkrb5/libgssapi_krb5
        fontconfig
        freetype
        xorg.libX11
        xorg.libxcb
        libglvnd # libGL.so.1 / libEGL.so.1 dispatch; NVIDIA vendor libs via addDriverRunpath
    ];

    dontStrip = true;

    installPhase = ''
runHook preInstall

mkdir -p $out/opt $out/share/applications $out/bin
cp -r opt/jopdf $out/opt/jopdf
cp -r usr/share/icons $out/share/

install -Dm644 usr/share/applications/jopdf.desktop $out/share/applications/jopdf.desktop
substituteInPlace $out/share/applications/jopdf.desktop \
    --replace-fail "/opt/jopdf/JOPDF" "jopdf"

makeWrapper $out/opt/jopdf/JOPDF $out/bin/jopdf \
    --prefix LD_LIBRARY_PATH : "${gpuLibPath}"

runHook postInstall
    '';

    meta = {
        description = "JOPDF free PDF editor, converter and reader";
        homepage = "https://www.jopdf.com";
        license = lib.licenses.unfree;
        sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
        platforms = [ "x86_64-linux" ];
        mainProgram = "jopdf";
    };
}

# <> #
