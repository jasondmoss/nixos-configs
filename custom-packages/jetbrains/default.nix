self: pkgs: with pkgs; {
    phpstorm = jetbrains.phpstorm.overrideAttrs (oldAttrs: {
        version = "2025.3.4";
        build = "253.32098.40";
        wmClass = "jetbrains";
        name = "phpstorm-2025.3.4";

        src = fetchurl {
            url = "https://download.jetbrains.com/webide/PhpStorm-2025.3.4.tar.gz";
            sha256 = "sha256-rUFOzut21nrAoKq88W8naa61Y/ncA7pn0MO3rGmuBIY=";
        };

        vmopts = ''
-server
-Xms6144m
-Xmx6144m
        '';
    });
}
