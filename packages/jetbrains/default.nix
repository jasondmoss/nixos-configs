self: pkgs: with pkgs; {
    phpstorm = jetbrains.phpstorm.overrideAttrs (oldAttrs: {
        version = "2025.2.1";
        build = "252.25557.128";
        src = fetchurl {
            url = "https://download.jetbrains.com/webide/PhpStorm-2025.2.1.tar.gz";
            sha256 = "sha256-DMkjUhDcCftUYC8XbeiBxPK2hS16Xyrp93UNg6P/qPY=";
        };

        name = "phpstorm-2025.2.1";
        wmClass = "jetbrains";
        vmopts = ''
-server
-Xms4096m
-Xmx4096m
        '';
    });
}
