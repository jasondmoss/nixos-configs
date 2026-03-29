self: pkgs: with pkgs; {
    phpstorm = jetbrains.phpstorm.overrideAttrs (oldAttrs: {
        version = "2026.1";
        build = "261.22158.283";
        wmClass = "jetbrains";
        name = "phpstorm-2026.1";

        src = fetchurl {
            url = "https://download.jetbrains.com/webide/PhpStorm-2026.1.tar.gz";
            sha256 = "sha256-OpSc/Xg4nWh9XRpVN8FLaV1Gwz8kbM+S9WVk27jJ7gY=";
        };

        vmopts = ''
-server
-Xms6144m
-Xmx6144m
        '';
    });
}
#self: pkgs: with pkgs; {
#    phpstorm = jetbrains.phpstorm.overrideAttrs (oldAttrs: {
#        version = "2025.3.4";
#        build = "253.32098.40";
#        wmClass = "jetbrains";
#        name = "phpstorm-2025.3.4";
#
#        src = fetchurl {
#            url = "https://download.jetbrains.com/webide/PhpStorm-2025.3.4.tar.gz";
#            sha256 = "sha256-rUFOzut21nrAoKq88W8naa61Y/ncA7pn0MO3rGmuBIY=";
#        };
#
#        vmopts = ''
#-server
#-Xms6144m
#-Xmx6144m
#        '';
#    });
#}
