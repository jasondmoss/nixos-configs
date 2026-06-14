{ lib, appimageTools, fetchurl }:
let
    pname = "audacity-beta";
    version = "4.0.0-beta2";

    src = fetchurl {
        url = "https://github.com/audacity/audacity/releases/download/Audacity-4.0.0-beta-2/Audacity-4.0.0-beta2-x86_64.AppImage";
        hash = "sha256-HL6cp4WTujsvKQZvTK5bhdhxz++zyzuukSt9I2oHGsQ=";
    };

    appimageContents = appimageTools.extract { inherit pname version src; };
in
appimageTools.wrapType2 {
    inherit pname version src;

    extraInstallCommands = ''
# Desktop entry — rewrite the bundled Exec/Icon (audacity4portable) to the
# wrapped binary name this package installs, and rename to audacity-beta so it
# can coexist with the stable `audacity` package.
install -Dm444 \
    ${appimageContents}/org.audacityteam.Audacity4portable.desktop \
    $out/share/applications/audacity-beta.desktop

substituteInPlace $out/share/applications/audacity-beta.desktop \
    --replace-fail "Exec=audacity4portable" "Exec=${pname}" \
    --replace-fail "Name=Audacity 4 Portable" "Name=Audacity 4 (beta)" \
    --replace-fail "Icon=audacity4portable" "Icon=audacity-beta"

# Icons — copy the hicolor theme tree, renaming the icon basename to match.
for size in 16x16 24x24 32x32 48x48 64x64 96x96 128x128 512x512; do
    src_icon=${appimageContents}/share/icons/hicolor/$size/apps/audacity4portable.png
    if [ -f "$src_icon" ]; then
        install -Dm444 "$src_icon" \
            $out/share/icons/hicolor/$size/apps/audacity-beta.png
    fi
done
    '';

    meta = {
        description = "Sound editor with graphical UI — 4.0 beta (Qt6/QML rewrite)";
        homepage = "https://www.audacityteam.org";
        changelog = "https://github.com/audacity/audacity/releases/tag/Audacity-4.0.0-beta-2";
        license = with lib.licenses; [ gpl2Plus gpl3 cc-by-30 ];
        sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
        platforms = [ "x86_64-linux" ];
        mainProgram = "audacity-beta";
    };
}

# <> #
