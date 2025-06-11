self: pkgs: with pkgs; {
    phpstorm = jetbrains.phpstorm.overrideAttrs (oldAttrs: {
        version = "2025.1.2";
        build = "251.26094.133";
        src = fetchurl {
            url = "https://download.jetbrains.com/webide/PhpStorm-2025.1.2.tar.gz";
            sha256 = "sha256-Ip86/ejjRm4dJi3pFUIPZqX8l4WHiMwI99DwuCbCp3s=";
        };

        name = "phpstorm-2025.1.2";
        wmClass = "jetbrains";
        vmopts = ''
-server
-Xms4096m
-Xmx4096m
        '';
    });
}
