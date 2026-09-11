{
    lib, stdenv, fetchurl, dpkg, makeWrapper, electron, libsecret, asar,
    python3, glib, desktop-file-utils,
}:

let
    ## Upstream GitHub releases (amd64 only — see meta.platforms). Version +
    ## checksum come from manifest.json — refresh it with ./update.sh (same
    ## workflow as packages/claude-desktop and packages/vivaldi-snapshot),
    ## then rebuild.
    baseUrl = "https://github.com/standardnotes/app/releases/download";
    manifest = lib.importJSON ./manifest.json;
in stdenv.mkDerivation {
    pname = "standardnotes";

    inherit (manifest) version;

    src = fetchurl {
        ## Release tag is the URL-encoded monorepo tag
        ## "@standardnotes/desktop@<version>".
        url = "${baseUrl}/%40standardnotes/desktop%40${manifest.version}/${manifest.filename}";
        inherit (manifest) sha256;
    };

    dontConfigure = true;
    dontBuild = true;

    nativeBuildInputs = [
        makeWrapper
        dpkg
        desktop-file-utils
        asar
    ];

    installPhase =
        let
            libPath = lib.makeLibraryPath [
                libsecret
                glib
                (lib.getLib stdenv.cc.cc)
            ];
        in
            ''
runHook preInstall

mkdir -p $out/bin $out/share/standardnotes
cp -R usr/share/{applications,icons} $out/share
cp -R opt/Standard\ Notes/resources/app.asar $out/share/standardnotes/
cp -R opt/Standard\ Notes/resources/app.asar.unpacked $out/share/standardnotes/
rm $out/share/standardnotes/app.asar.unpacked/node_modules/cbor-extract/build/node_gyp_bins/python3
ln -s ${python3.interpreter} $out/share/standardnotes/app.asar.unpacked/node_modules/cbor-extract/build/node_gyp_bins/python3

asar e $out/share/standardnotes/app.asar asar-unpacked
find asar-unpacked -name '*.node' -exec patchelf \
 --add-rpath "${libPath}" \
 {} \;
asar p asar-unpacked $out/share/standardnotes/app.asar

makeWrapper ${electron}/bin/electron $out/bin/standardnotes \
 --add-flags $out/share/standardnotes/app.asar

${desktop-file-utils}/bin/desktop-file-install --dir $out/share/applications \
 --set-key Exec --set-value standardnotes usr/share/applications/standard-notes.desktop

runHook postInstall
            '';

    meta = {
        description = "Simple and private notes app";
        longDescription = ''
            Standard Notes is a private notes app that features unmatched simplicity,
            end-to-end encryption, powerful extensions, and open-source applications.
        '';
        homepage = "https://standardnotes.org";
        license = lib.licenses.agpl3Only;
        maintainers = with lib.maintainers; [
            mgregoire
            chuangzhu
            squalus
        ];
        sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
        platforms = [ "x86_64-linux" ];
        mainProgram = "standardnotes";
    };
}

# <> #
