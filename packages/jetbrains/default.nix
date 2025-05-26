#self: pkgs: with pkgs; {
#    phpstorm = jetbrains.phpstorm.overrideAttrs (oldAttrs: {
#        version = "2025.2";
#        build = "252.16512.27";
#        src = fetchurl {
#            url = "https://download.jetbrains.com/webide/PhpStorm-252.16512.27.tar.gz";
#            sha256 = "sha256-RrMeyC9Zoe/BDmjlmE8mPM2DhNWTvtxIIHyJ3kebHWs=";
#        };
#
#        name = "phpstorm-2025.2.EAP-2";
#        wmClass = "jetbrains";
#        vmopts = ''
#-server
#-Xms4096m
#-Xmx4096m
#        '';
#    });
#}
self: pkgs: with pkgs; {
    phpstorm = jetbrains.phpstorm.overrideAttrs (oldAttrs: {
        version = "2025.1.2";
        build = "251.26094.44";
        src = fetchurl {
            url = "https://download.jetbrains.com/webide/PhpStorm-251.26094.44.tar.gz";
            sha256 = "sha256-gzvYT70KhCbNW9jUar+ymBTL3zQ4UCZjp0oX3wVXxHk=";
        };

        name = "phpstorm-2025.1.2";
        wmClass = "jetbrains";
        vmopts = ''
-server
-Xms4096m
-Xmx4096m
        '';
    });
}
