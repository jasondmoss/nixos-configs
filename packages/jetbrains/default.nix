#self: pkgs: with pkgs; {
#    phpstorm = jetbrains.phpstorm.overrideAttrs (oldAttrs: {
#        version = "2025.2.EAP";
#        build = "252.13776.56";
#        src = fetchurl {
#            url = "https://download.jetbrains.com/webide/PhpStorm-252.13776.56.tar.gz";
#            sha256 = "sha256-EIe7ARrORtwbM6w8UnRRf7eZDumMeJeeHftE39zkzhw=";
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
