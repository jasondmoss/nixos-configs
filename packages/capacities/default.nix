{
    lib, fetchurl, appimageTools, makeWrapper, commandLineArgs ? ""
}:
let
    pname = "capacities";
    version = "1.47.2";
    name = "Capacities-${version}";
    src = fetchurl {
        url = "https://capacities-desktop-app.fra1.cdn.digitaloceanspaces.com/${name}.AppImage";
        hash = "sha256-2WwGk2FP2z4DkRiM/HcwcMV/MfzY11ZpddhQnzfUrBI=";
    };

    appimageContents = appimageTools.extractType2 { inherit pname version src; };
in appimageTools.wrapType2 {
    inherit pname version src;

    nativeBuildInputs = [
        makeWrapper
    ];

    extraPkgs = pkgs: [
        pkgs.libsecret
    ];

    extraInstallCommands = ''
wrapProgram $out/bin/${pname}\
 --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true}}"\
 --add-flags ${lib.escapeShellArg commandLineArgs}
install -m 444 -D ${appimageContents}/${pname}.desktop -t $out/share/applications
substituteInPlace $out/share/applications/${pname}.desktop\
 --replace 'Exec=AppRun' 'Exec=${pname}'
for size in 16 32 64 128 256 512 1024; do
    install -m 444 -D ${appimageContents}/usr/share/icons/hicolor/''${size}x''${size}/apps/${pname}.png\
 $out/share/icons/hicolor/''${size}x''${size}/apps/${pname}.png
done
    '';

    meta = with lib; {
        description = "A Studio for Your Mind";
        homepage = "https://capacities.io/";
        license = licenses.unfree;
        mainProgram = "capacities";
        maintainers = with maintainers; [ running-grass ];
        platforms = [ "x86_64-linux" ];
    };
}
