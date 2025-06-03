self: pkgs: with pkgs; {
    phpstorm = jetbrains.phpstorm.overrideAttrs (oldAttrs: {
        version = "2025.1.2";
        build = "251.26094.108";
        src = fetchurl {
            url = "https://download.jetbrains.com/webide/PhpStorm-251.26094.108.tar.gz";
            sha256 = "sha256-4R6ZaxWGB3j2aatxy1qkKmTYxpwm+5v6xfxmHxjbrds=";
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
