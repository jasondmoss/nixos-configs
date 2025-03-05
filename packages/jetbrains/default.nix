self: pkgs: with pkgs; {
    phpstorm = jetbrains.phpstorm.overrideAttrs (oldAttrs: {
        version = "2024.3.3";
        build = "243.23654.168";
        src = fetchurl {
            url = "https://download.jetbrains.com/webide/PhpStorm-2024.3.3.tar.gz";
            sha256 = "sha256-J0AB/A5ijtm1SW8k2hHT6X8HsP4/RTAyNcN9EkEhoUo=";
        };

        name = "phpstorm-2024.3.3";
        wmClass = "jetbrains";
        vmopts = ''
-server
-Xms4096m
-Xmx4096m
        '';
    });
}
