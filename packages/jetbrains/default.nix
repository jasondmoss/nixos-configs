self: pkgs: with pkgs; {
    phpstorm = jetbrains.phpstorm.overrideAttrs (oldAttrs: {
        version = "2026.1.2";
        build = "261.24374.185";
        wmClass = "jetbrains";
        name = "phpstorm-2026.1.2";

        src = fetchurl {
            url = "https://download.jetbrains.com/webide/PhpStorm-2026.1.2.tar.gz";
            sha256 = "sha256-VbXsfKahp1X4AwAC10VghE+ZkxThovnYHHYyvkOTtFc=";
        };

        vmopts = ''
-server
-Xms6144m
-Xmx6144m
        '';
    });
}

# <> #
