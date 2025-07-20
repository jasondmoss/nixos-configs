self: pkgs: with pkgs; {
    phpstorm = jetbrains.phpstorm.overrideAttrs (oldAttrs: {
        version = "2025.1.3";
        build = "251.26927.60";
        src = fetchurl {
            url = "https://download.jetbrains.com/webide/PhpStorm-2025.1.3.tar.gz";
            sha256 = "229f3afde8e3466e1d262de915420f66a5fc97858788cc08f7d0f0b826c2a77b";
        };

        name = "phpstorm-2025.1.3";
        wmClass = "jetbrains";
        vmopts = ''
-server
-Xms4096m
-Xmx4096m
        '';
    });
}

# self: pkgs: with pkgs; {
#     phpstorm = jetbrains.phpstorm.overrideAttrs (oldAttrs: {
#         version = "2025.1.3";
#         build = "251.26927.60";
#         src = fetchurl {
#             url = "https://download.jetbrains.com/webide/PhpStorm-2025.1.3.tar.gz";
#             sha256 = "sha256-zBE+D2ZxwK7vQhIvSzrinye4k/8YBJfqurhCzlqbLKI=";
#         };

#         name = "phpstorm-2025.1.3";
#         wmClass = "jetbrains";
#         vmopts = ''
# -server
# -Xms4096m
# -Xmx4096m
#         '';
#     });
# }

