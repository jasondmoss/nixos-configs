self: pkgs: with pkgs; {
    phpstorm = jetbrains.phpstorm.overrideAttrs (oldAttrs: {
        version = "2025.1.4.1";
        build = "251.27812.24";
        src = fetchurl {
            url = "https://download.jetbrains.com/webide/PhpStorm-2025.1.4.1.tar.gz";
            sha256 = "sha256-ks2NVw0DBxiBkHYcfNDQ93NR/xGXNQc8KhAeSjZCkrQ=";
        };

        name = "phpstorm-2025.1.4";
        wmClass = "jetbrains";
        vmopts = ''
-server
-Xms4096m
-Xmx4096m
        '';
    });
}

/*self: pkgs: with pkgs; {
    phpstorm = jetbrains.phpstorm.overrideAttrs (oldAttrs: {
        version = "2025.2";
        build = "252.23892.178";
        src = fetchurl {
            url = "https://download.jetbrains.com/webide/PhpStorm-252.23892.178.tar.gz";
            sha256 = "sha256-85W6EtpQ4BvD+Q2a44P/JZzrm7GDYfo5Ir0HDvwMoAU=";
        };

        name = "phpstorm-2025.2.EAP";
        wmClass = "jetbrains";
        vmopts = ''
-server
-Xms4096m
-Xmx4096m
        '';
    });
}*/
