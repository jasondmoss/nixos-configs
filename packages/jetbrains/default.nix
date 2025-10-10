self: pkgs: with pkgs; {

    phpstorm = jetbrains.phpstorm.overrideAttrs (oldAttrs: {
        version = "2025.2.3";
        build = "252.26830.95";
        src = fetchurl {
            url = "https://download.jetbrains.com/webide/PhpStorm-2025.2.3.tar.gz";
            sha256 = "sha256-s03bZMyEucopt9FxxxKWqri9h9em1+sRxBDg5ZqBpR0=";
        };

        name = "phpstorm-2025.2.3";
        wmClass = "jetbrains";
        vmopts = ''
-server
-Xms6144m
-Xmx6144m
        '';
#-Xms4096m
#-Xmx4096m
    });

}
