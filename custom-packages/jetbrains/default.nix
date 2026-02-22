self: pkgs: with pkgs; {
    phpstorm = jetbrains.phpstorm.overrideAttrs (oldAttrs: {
        version = "2025.3.3";
        build = "253.31033.138";
        wmClass = "jetbrains";
        name = "phpstorm-2025.3.3";

        src = fetchurl {
            url = "https://download.jetbrains.com/webide/PhpStorm-2025.3.3.tar.gz";
            sha256 = "sha256-CX7LgeWLKAFYcDHubXqQt9Shz5EVscly/dMwHmz6ht4=";
        };

        vmopts = ''
-server
-Xms6144m
-Xmx6144m
        '';
    });
}
