{
    steam, makeDesktopItem, writeShellScriptBin, symlinkJoin,
    libxcb-wm, libxcb-util, libxcb-image, libxcb-keysyms, libxcb-render-util,
    libxcb-cursor, libsecret,
}:

#-- Clate — Qt's no-code HMI/UX design tool (beta, QML under the hood).
#--
#-- Not packaged from source: Qt ships a prebuilt, account-gated offline
#-- installer (clate-<ver>-linux-x86_64.run from qt.io/design/clate) that needs
#-- a Qt Account browser sign-in and an evaluation-agreement acceptance, so
#-- the app itself lives where that installer puts it —
#-- ~/.config/ClateBeta<NN>/Tools/Clate (0.6.0 → ClateBeta06) — and this
#-- package is only the launcher around it. Run the installer the same way:
#--     clate-installer ~/Downloads/clate-<ver>-linux-x86_64.run
#--
#-- Runtime: a steam-run FHS env. Both the installer (static Qt, xcb only) and
#-- the app (bundled Qt 6.12 incl. the wayland platform plugin) expect FHS
#-- libraries; plain steam-run lacks the xcb-util set and libsecret, so they
#-- are added via extraPkgs (64-bit targetPkgs — extraLibraries would drag in
#-- i686 builds too). Still missing and harmless: optional Qt plugins (SQL
#-- drivers, gtk3 platform theme, speech, PC/SC).
#--
#-- Environment scrubbing (verified 2026-11-05 against 0.6.0):
#--   QML_DISABLE_DISK_CACHE — Clate ships its QML AOT-compiled with the
#--     source stripped from qrc; with the cache disabled Qt ignores the
#--     compiled units, parses the empty placeholders and every panel fails
#--     with "Expected token `numeric literal'" at 1:1. Krema's wrapper
#--     exported it to everything launched from the dock until 2026-11-05
#--     (packages/krema); kept here in case any other parent sets it.
#--   QT_PLUGIN_PATH / QML*_IMPORT_PATH — point at nixpkgs Qt/KF6 plugins and
#--     modules; keep them out of the bundled Qt.
#--   QT_QPA_PLATFORMTHEME — "kde" isn't loadable by the bundled Qt; use the
#--     bundled xdgdesktopportal theme instead (KDE file dialogs via portal).

let
    fhs = (steam.override {
        extraPkgs = _: [
            libxcb-wm libxcb-util libxcb-image libxcb-keysyms
            libxcb-render-util libxcb-cursor libsecret
        ];
    }).run;

    scrub = ''
        unset QML_DISABLE_DISK_CACHE QT_PLUGIN_PATH QML2_IMPORT_PATH \
              QML_IMPORT_PATH NIXPKGS_QT6_QML_IMPORT_PATH
        export QT_QPA_PLATFORMTHEME=xdgdesktopportal
    '';

    launcher = writeShellScriptBin "clate" ''
        root="''${CLATE_HOME:-}"
        if [ -z "$root" ]; then
            # Each beta installs to its own ClateBeta<NN>; the glob sorts
            # lexically, so the newest zero-padded beta comes last.
            shopt -s nullglob
            installs=("$HOME"/.config/ClateBeta*/Tools/Clate)
            [ ''${#installs[@]} -gt 0 ] && root="''${installs[-1]}"
        fi
        if [ ! -x "$root/bin/clate.sh" ]; then
            echo "clate: no install under ~/.config/ClateBeta*/Tools/Clate (set CLATE_HOME)" >&2
            exit 1
        fi
        ${scrub}
        exec ${fhs}/bin/steam-run "$root/bin/clate.sh" "$@"
    '';

    installer = writeShellScriptBin "clate-installer" ''
        if [ ! -f "''${1:-}" ]; then
            echo "usage: clate-installer <clate-<ver>-linux-x86_64.run>" >&2
            exit 1
        fi
        ${scrub}
        exec ${fhs}/bin/steam-run "$(realpath "$1")" "''${@:2}"
    '';

    #-- Named after the app ID Clate registers with the portal; without a
    #-- matching desktop file the portal logs "App info not found".
    #-- custom-clate.png in ~/.icons/hicolor/512x512/apps is Clate's own
    #-- 512px icon (theme name, not a path, so Krema can render it).
    desktopItem = makeDesktopItem {
        name = "io.qt.qmldesigner";
        desktopName = "Clate";
        genericName = "UI Designer for QML applications";
        exec = "clate %F";
        icon = "custom-clate";
        startupWMClass = "org.qt-project.qmldesigner";
        categories = [ "Development" "GUIDesigner" "Qt" ];
        terminal = false;
    };
in symlinkJoin {
    name = "clate-launcher";
    paths = [ launcher installer desktopItem ];
}

# <> #
