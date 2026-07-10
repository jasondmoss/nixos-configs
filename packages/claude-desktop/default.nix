{
    addDriverRunpath, alsa-lib, at-spi2-core, autoPatchelfHook, cups, dpkg,
    expat, fetchurl, gtk3, lib, libcap_ng, libdrm, libglvnd, libnotify,
    libseccomp, libsecret,
    libx11, libxcb, libxcomposite, libxdamage, libxext, libxfixes,
    libxkbcommon, libxrandr, libxscrnsaver, libxshmfence, libxtst,
    makeWrapper, mesa, nspr, nss, stdenv, systemd, vulkan-loader, xdg-utils
}:
with lib;

let
    version = "1.18286.2";

    ## Upstream apt repository (same pool the Debian/Ubuntu install uses):
    ## https://code.claude.com/docs/en/desktop-linux
    src = fetchurl {
        url = "https://downloads.claude.ai/claude-desktop/apt/stable/pool/main/c/claude-desktop/claude-desktop_${version}_amd64.deb";
        sha256 = "sha256-Vvpd4FPgpo3HWDZ3hXvtz0IZsZ2QIBQA4CN7fXTVEvE=";
    };

    meta = with lib; {
        description = "Claude desktop application (Chat, Cowork and Claude Code)";
        homepage = "https://claude.ai";
        platforms = [ "x86_64-linux" ];
        sourceProvenance = with sourceTypes; [ binaryNativeCode ];
        license = licenses.unfree;
        mainProgram = "claude-desktop";
    };

    ## GPU library path: libglvnd (EGL/GL dispatcher) + vulkan-loader +
    ## NVIDIA driver libraries via addDriverRunpath.
    gpuLibPath = lib.makeLibraryPath [
        libglvnd
        vulkan-loader
    ] + ":${addDriverRunpath.driverLink}/lib";
in
stdenv.mkDerivation {
    pname = "claude-desktop";
    inherit version;
    inherit meta;
    inherit src;

    nativeBuildInputs = [ autoPatchelfHook dpkg makeWrapper ];

    buildInputs = [
        alsa-lib
        at-spi2-core
        cups
        expat
        gtk3
        libcap_ng
        libdrm
        libseccomp
        libsecret
        libx11
        libxcb
        libxcomposite
        libxdamage
        libxext
        libxfixes
        libxkbcommon
        libxrandr
        libxscrnsaver
        libxshmfence
        libxtst
        mesa
        nspr
        nss
    ];

    runtimeDependencies = [ (getLib systemd) libnotify ];

    ## chrome-sandbox ships setuid root, which tar cannot recreate inside
    ## the build sandbox — strip ownership/permission bits on extract.
    unpackPhase = ''
dpkg-deb --fsys-tarfile $src | tar --extract --no-same-owner --no-same-permissions
    '';

    installPhase = ''
mkdir -p $out
cp -r usr/lib usr/share $out/

# The .deb ships its own desktop file and hicolor icons; only the
# launcher symlink needs replacing with a wrapper.
    '';

    postFixup = ''
mkdir -p $out/bin
makeWrapper $out/lib/claude-desktop/claude-desktop $out/bin/claude-desktop \
 --prefix PATH : ${xdg-utils}/bin \
 --prefix LD_LIBRARY_PATH : "${gpuLibPath}" \
 --add-flags "--ozone-platform-hint=auto"
    '';
}

# <> #
