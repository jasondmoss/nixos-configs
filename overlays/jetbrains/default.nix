self: pkgs: with pkgs; {

    phpstorm = jetbrains.phpstorm.overrideAttrs (oldAttrs: {
        version = "2024.3";
        build = "243.21565.202";
        src = fetchurl {
            url = "https://download.jetbrains.com/webide/PhpStorm-2024.3.tar.gz";
            sha256 = "sha256-YOOaFNrXf/p7Ljb3AdxNXFuygSMdBtfCkoB0g6aHkHE=";
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
