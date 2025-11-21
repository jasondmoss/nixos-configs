self: pkgs: with pkgs; {
    phpstorm = jetbrains.phpstorm.overrideAttrs (oldAttrs: {
        version = "2025.2.5";
        build = "252.28238.9";
        wmClass = "jetbrains";
        name = "phpstorm-2025.2.5";

        src = fetchurl {
            url = "https://download.jetbrains.com/webide/PhpStorm-2025.2.5.tar.gz";
            sha256 = "sha256-TxAruFrdJSfkZpXzuGbA4xVCPhm8ReCtsN4P5Xeh7+Y=";
        };

        vmopts = ''
-server
-Xms6144m
-Xmx6144m
        '';
    });
}
