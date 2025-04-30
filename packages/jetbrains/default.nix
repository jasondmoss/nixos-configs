self: pkgs: with pkgs; {
    phpstorm = jetbrains.phpstorm.overrideAttrs (oldAttrs: {
        version = "2025.1.1";
        build = "251.25410.64";
        src = fetchurl {
            url = "https://download.jetbrains.com/webide/PhpStorm-251.25410.64.tar.gz";
            sha256 = "sha256-pxiYnS9THRxRM6K1ery2TJKojrlRqUrFJ3MZesYbc14=";
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
#self: pkgs: with pkgs; {
#    phpstorm = jetbrains.phpstorm.overrideAttrs (oldAttrs: {
#        version = "2025.1.0.1";
#        build = "251.23774.466";
#        src = fetchurl {
#            url = "https://download.jetbrains.com/webide/PhpStorm-2025.1.0.1.tar.gz";
#            sha256 = "sha256-U+JhHxKDcl+XGDIpr7uxSXoFc5QxQLKvQuDZ0iY5Lhw=";
#        };
#
#        name = "phpstorm-2025.1.0.1";
#        wmClass = "jetbrains";
#        vmopts = ''
#-server
#-Xms4096m
#-Xmx4096m
#        '';
#    });
#}
