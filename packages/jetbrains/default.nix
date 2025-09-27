self: pkgs: with pkgs; {

    phpstorm = jetbrains.phpstorm.overrideAttrs (oldAttrs: {
        version = "2025.2.2";
        build = "252.26199.163";
        src = fetchurl {
            url = "https://download.jetbrains.com/webide/PhpStorm-2025.2.2.tar.gz";
            sha256 = "sha256-EBDEz+0NdKAIjIDpZsDqde0SONxbiuJREei+Pga950E=";
        };

        name = "phpstorm-2025.2.2";
        wmClass = "jetbrains";
        vmopts = ''
-server
-Xms4096m
-Xmx4096m
        '';
    });

}
