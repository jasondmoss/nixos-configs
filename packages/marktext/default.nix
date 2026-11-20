{
    lib, appimageTools, fetchurl, makeWrapper, desktop-file-utils,
}:

let
    ## Upstream GitHub releases (x86_64 AppImage). Version + checksum come
    ## from manifest.json — refresh it with ./update.sh (same workflow as
    ## packages/standardnotes), then rebuild.
    ##
    ## Why the AppImage rather than nixpkgs' `marktext` (a source build still
    ## at 0.19.1 — upstream resumed in 2026 and moved on) or the
    ## standardnotes pattern (app.asar on nixpkgs' electron): each release
    ## bundles its own Electron (0.23.0 → Electron 42.1.0) with native
    ## modules (keytar, ced, native-keymap) built for that ABI, and the app
    ## loads `process.resourcesPath/static/locales`, which would resolve
    ## into nixpkgs' electron. The AppImage keeps both as upstream ships them.
    baseUrl = "https://github.com/marktext/marktext/releases/download";
    manifest = lib.importJSON ./manifest.json;

    pname = "marktext";
    inherit (manifest) version;

    src = fetchurl {
        url = "${baseUrl}/v${version}/${manifest.filename}";
        inherit (manifest) sha256;
    };

    appimageContents = appimageTools.extract { inherit pname version src; };
in appimageTools.wrapType2 {
    inherit pname version src;

    ## native-keymap's keymapping.node links libxkbfile, which the default
    ## AppImage FHS set lacks: the module fails to load and keybindings fall
    ## back to the US map ("Cannot read properties of null (reading
    ## 'getKeyMap')" on stderr). keytar's libsecret is already in the set.
    extraPkgs = pkgs: [ pkgs.libxkbfile ];

    extraInstallCommands = ''
source ${makeWrapper}/nix-support/setup-hook

## Same Wayland switch as nixpkgs' own Electron apps: NIXOS_OZONE_WL is set
## in system/environment.nix, and without the hint the app runs on XWayland.
wrapProgram $out/bin/marktext \
 --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true}}"

install -Dm444 ${appimageContents}/usr/share/icons/hicolor/256x256/apps/marktext.png \
 $out/share/icons/hicolor/256x256/apps/marktext.png

## Upstream's entry runs `AppRun --no-sandbox` and repeats text/markdown
## seven times; point it at the wrapper and give Dolphin both Markdown types.
${desktop-file-utils}/bin/desktop-file-install --dir $out/share/applications \
 --set-key Exec --set-value 'marktext %U' \
 --set-key MimeType --set-value 'text/markdown;text/x-markdown;' \
 ${appimageContents}/marktext.desktop
    '';

    meta = {
        description = "Simple and elegant Markdown editor with Typora-style live preview";
        homepage = "https://github.com/marktext/marktext";
        changelog = "https://github.com/marktext/marktext/releases/tag/v${version}";
        license = lib.licenses.mit;
        sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
        platforms = [ "x86_64-linux" ];
        mainProgram = "marktext";
    };
}

# <> #
