self: pkgs: with pkgs; {

    phpstorm = jetbrains.phpstorm.overrideAttrs (oldAttrs: {
        version = "2024.3.1";
        build = "243.22562.74";
        src = fetchurl {
            url = "https://download.jetbrains.com/webide/PhpStorm-243.22562.74.tar.gz";
            sha256 = "sha256-Bd0BeYbmkvTia0dq5t9lCIwIHJVCsSlbb9yHzvVphVg=";
        };

        name = "phpstorm-2024.3.1";
        wmClass = "jetbrains";

        vmopts = ''
-server
-Xms4096m
-Xmx4096m
        '';
    });

}
