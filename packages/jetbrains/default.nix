self: pkgs: with pkgs; {
    phpstorm = jetbrains.phpstorm.overrideAttrs (oldAttrs: {
        version = "2025.1.1";
        build = "251.25410.148";
        src = fetchurl {
            url = "https://download.jetbrains.com/webide/PhpStorm-2025.1.1.tar.gz";
            sha256 = "sha256-tkci6nFduFZnVJeK9hdxYBbeqizaNSHPBeSgSeW79qM=";
        };

        name = "phpstorm-2025.1.1";
        wmClass = "jetbrains";
        vmopts = ''
-server
-Xms4096m
-Xmx4096m
        '';
    });
}
