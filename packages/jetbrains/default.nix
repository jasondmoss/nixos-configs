self: pkgs: with pkgs; {
    phpstorm = jetbrains.phpstorm.overrideAttrs (oldAttrs: {
        version = "2025.3.1";
        build = "253.29346.151";
        wmClass = "jetbrains";
        name = "phpstorm-2025.3.1";

        src = fetchurl {
            url = "https://download.jetbrains.com/webide/PhpStorm-2025.3.1.tar.gz";
            sha256 = "sha256-/Yk3q2t5YFzvyZF//moI4FprfMAlb6IXhiPSTsMi+ik=";
        };

        vmopts = ''
-server
-Xms6144m
-Xmx6144m
        '';
    });
}
