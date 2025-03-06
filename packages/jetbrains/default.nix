self: pkgs: with pkgs; {
    phpstorm = jetbrains.phpstorm.overrideAttrs (oldAttrs: {
        version = "2024.3.4";
        build = "243.25659.45";
        src = fetchurl {
            url = "https://download.jetbrains.com/webide/PhpStorm-2024.3.4.tar.gz";
            sha256 = "sha256-k0TWjdosAGLZ9vA+J+lZNG8vK7orzp8cEIZTCQ0t+4U=";
        };

        name = "phpstorm-2024.3.4";
        wmClass = "jetbrains";
        vmopts = ''
-server
-Xms4096m
-Xmx4096m
        '';
    });
}
