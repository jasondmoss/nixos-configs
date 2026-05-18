self: pkgs: with pkgs; {
    phpstorm = jetbrains.phpstorm.overrideAttrs (oldAttrs: {
        version = "2026.1.1";
        build = "261.23567.149";
        wmClass = "jetbrains";
        name = "phpstorm-2026.1.1";

        src = fetchurl {
            url = "https://download.jetbrains.com/webide/PhpStorm-2026.1.1.tar.gz";
            sha256 = "sha256-TOSiFAphV/JYrUg9tB/BAtAGjn6P0DpaYHO2W3FcCGQ=";
        };

        vmopts = ''
-server
-Xms6144m
-Xmx6144m
        '';
    });
}

# <> #
