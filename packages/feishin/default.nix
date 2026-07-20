{
    lib, buildNpmPackage, fetchFromGitHub, electron_41, mpv-unwrapped,
    fetchPnpmDeps, pnpmConfigHook, pnpm_11, copyDesktopItems,
    makeDesktopItem
}:

let
    pname = "feishin";
    version = "development";

    src = fetchFromGitHub {
        owner = "jeffvli";
        repo = "feishin";
        rev = version;
        hash = "sha256-VXvaruxT6Vr4kr4r1MkDtzEpwHzwQ9LCiRAkZj1JvV4=";
    };

    electron = electron_41;
in
buildNpmPackage {
    inherit pname version src;

    __structuredAttrs = true;

    npmConfigHook = pnpmConfigHook;
    npmBuildScript = "build";

    npmDeps = null;
    pnpmDeps = fetchPnpmDeps {
        inherit pname version src;
        pnpm = pnpm_11;
        fetcherVersion = 4;
        hash = "sha256-9uG0AxIBAmuIPywg3p9fFCXmRvM9zDLhWfluSLRnUXY=";
    };

    env.ELECTRON_SKIP_BINARY_DOWNLOAD = "1";

    nativeBuildInputs = [
        pnpm_11
        copyDesktopItems
    ];

    postPatch = ''
# release/app dependencies are installed on preConfigure
substituteInPlace package.json \
 --replace-fail '"postinstall": "electron-builder install-app-deps",' ""
    '';

    postBuild = ''
cp -r ${electron.dist} electron-dist
chmod -R u+w electron-dist

npm exec electron-builder -- \
 --dir \
 -c.electronDist=electron-dist \
 -c.electronVersion=${electron.version} \
 -c.npmRebuild=false
    '';

    installPhase = ''
runHook preInstall

mkdir -p $out/share/feishin

pushd dist/*-unpacked/
cp -r locales resources{,.pak} $out/share/feishin
popd

# Code relies on checking app.isPackaged, which returns false if the
# executable is electron; force it on.
# https://github.com/electron/electron/issues/35153#issuecomment-1202718531
makeWrapper ${lib.getExe electron} $out/bin/feishin \
 --prefix PATH : "${lib.makeBinPath [ mpv-unwrapped ]}" \
 --add-flags $out/share/feishin/resources/app.asar \
 --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true}}" \
 --set ELECTRON_FORCE_IS_PACKAGED 1 \
 --set DISABLE_AUTO_UPDATES 1 \
 --inherit-argv0

install -Dm644 org.jeffvli.feishin.metainfo.xml $out/share/metainfo/org.jeffvli.feishin.metainfo.xml

for size in 32 64 128 256 512 1024; do
    mkdir -p $out/share/icons/hicolor/"$size"x"$size"/apps
    ln -s \
     $out/share/feishin/resources/assets/icons/"$size"x"$size".png \
     $out/share/icons/hicolor/"$size"x"$size"/apps/feishin.png
done

runHook postInstall
    '';

    desktopItems = [
        (makeDesktopItem {
            name = "feishin";
            desktopName = "Feishin";
            comment = "Full-featured Jellyfin, Navidrome, and OpenSubsonic Compatible Music Player";
            icon = "feishin";
            exec = "feishin %u";
            categories = [
                "Audio"
                "AudioVideo"
                "Player"
                "Music"
            ];
            mimeTypes = [ "x-scheme-handler/feishin" ];
        })
    ];

    meta = {
        description = "Full-featured Jellyfin, Navidrome, and OpenSubsonic Compatible Music Player (development branch)";
        homepage = "https://github.com/jeffvli/feishin";
        license = lib.licenses.gpl3Plus;
        platforms = lib.platforms.linux;
        mainProgram = "feishin";
    };
}

# <> #
