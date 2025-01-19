self: pkgs: with pkgs; {

    phpstorm = jetbrains.phpstorm.overrideAttrs (oldAttrs: {
        #version = "2024.3.2";
        #build = "243.23654.115";
        #src = fetchurl {
        #    url = "https://download.jetbrains.com/webide/PhpStorm-2024.3.2.tar.gz";
        #    sha256 = "sha256-ki8R+He2bRgV1UQLSJFCEmnS0jURLi+mJwthCW2zbC8=";
        #};
        version = "2025.1";
        build = "251.14649.45";
        src = fetchurl {
            url = "https://download.jetbrains.com/webide/PhpStorm-251.14649.45.tar.gz";
            sha256 = "sha256-t1kRGJJjYbjF8L1VtU+jl4HE8pOC+rvabCckqgUF458=";
        };

        #name = "phpstorm-2024.3.2";
        name = "phpstorm-2025.1";
        wmClass = "jetbrains";

        vmopts = ''
-server
-Xms4096m
-Xmx4096m
        '';
    });

}
