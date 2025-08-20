{ pkgs, config, ... }:
let
    ngrok = builtins.fetchGit {
        url = "https://github.com/ngrok/ngrok-nix";
        rev = "c56189898f263153a2a16775ea2b871084a4efb0";
    };
in {
    imports = [
        "${ngrok}/nixos.nix"
    ];

    services.ngrok = {
        enable = true;
#        authToken = "2qZtsiVH7Q5NW3j10CaXp9RqnKx_4pVp9YJsW8PhPqHKQe5Sz";
        extraConfig = { };
        extraConfigFiles = [
            # reference to files containing `authtoken` and `api_key` secrets
            # ngrok will merge these, together with `extraConfig`
            "/home/me/Mega/System/Configurations/ngrok/ngrok.yml"
        ];
        tunnels = {
            web = {
                protocol = "http";
                port = 8080;
#                subdomain = "myapp"; # Uncomment if you have a paid plan
            };

            ssh = {
                protocol = "tcp";
                port = 22;
            };
        };
    };
}
