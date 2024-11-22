self: pkgs: with pkgs; {

    phpstorm = jetbrains.phpstorm.overrideAttrs (oldAttrs: {
        version = "2024.3.1";
        build = "243.22562.9";
        src = fetchurl {
            url = "https://download.jetbrains.com/webide/PhpStorm-243.22562.9.tar.gz";
            sha256 = "sha256-4/OmNj0Ra3v153R+gz82qvDDm3KQtLfc7VmWM/OxSxw=";
        };

        name = "phpstorm-2024.3.1";
        wmClass = "jetbrains";

        vmopts = ''
-server
-Xms4096m
-Xmx4096m
        '';
    });

}
