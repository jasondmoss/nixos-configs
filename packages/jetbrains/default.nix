self: pkgs: with pkgs; {
    phpstorm = jetbrains.phpstorm.overrideAttrs (oldAttrs: {
        version = "2025.1.3";
        build = "251.26927.60";
        src = fetchurl {
            url = "https://download.jetbrains.com/webide/PhpStorm-2025.1.3.tar.gz";
            sha256 = "sha256-zBE+D2ZxwK7vQhIvSzrinye4k/8YBJfqurhCzlqbLKI=";
        };

        name = "phpstorm-2025.1.3";
        wmClass = "jetbrains";
        vmopts = ''
-server
-Xms4096m
-Xmx4096m
        '';
    });
}
#self: pkgs: with pkgs; {
#    phpstorm = jetbrains.phpstorm.overrideAttrs (oldAttrs: {
#        version = "2025.2.EAP.7";
#        build = "252.23591.32";
#        src = fetchurl {
#            url = "https://download.jetbrains.com/webide/PhpStorm-252.23591.32.tar.gz";
#            sha256 = "sha256-qsIEhe3vuPxPHgzzwjaJH/UfrY9o6l/M/me9e7F1eIo=";
#        };
#
#        name = "phpstorm-2025.2.EAP";
#        wmClass = "jetbrains";
#        vmopts = ''
#-server
#-Xms4096m
#-Xmx4096m
#        '';
#    });
#}
