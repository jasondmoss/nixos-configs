self: pkgs: with pkgs; {

    phpstorm = jetbrains.phpstorm.overrideAttrs (oldAttrs: {
        version = "2024.3.2";
        build = "243.23654.115";
        src = fetchurl {
            url = "https://download.jetbrains.com/webide/PhpStorm-2024.3.2.tar.gz";
            sha256 = "sha256-ki8R+He2bRgV1UQLSJFCEmnS0jURLi+mJwthCW2zbC8=";
        };

        name = "phpstorm-2024.3.2";
        wmClass = "jetbrains";

        vmopts = ''
-server
-Xms4096m
-Xmx4096m
        '';
    });

}
