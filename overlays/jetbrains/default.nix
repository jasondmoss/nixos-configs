self: pkgs: with pkgs; {

    phpstorm = jetbrains.phpstorm.overrideAttrs (oldAttrs: {
        version = "2024.3";
        build = "243.21565.34";
        src = fetchurl {
            url = "https://download.jetbrains.com/webide/PhpStorm-243.21565.34.tar.gz";
            sha256 = "sha256-Qn+F4DoaygESAX/UeWtfC670wMioxzMjTJmwLWJ55BQ=";
        };

        name = "phpstorm-2024.3";
        wmClass = "jetbrains";

        vmopts = ''
-server
-Xms4096m
-Xmx4096m
        '';
    });

}
