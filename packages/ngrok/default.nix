{ pkgs, config, ... }:
let
    ngrok = builtins.fetchGit {
        url = "https://github.com/ngrok/ngrok-nix";
        rev = "c56189898f263153a2a16775ea2b871084a4efb0";
    };
in {
#    nixpkgs.config.allowUnfree = true;

    imports = [
        "${ngrok}/nixos.nix"
    ];

    services.ngrok = {
        enable = true;
        extraConfig = {};
        extraConfigFiles = [
          # reference to files containing `authtoken` and `api_key` secrets
          # ngrok will merge these, together with `extraConfig`
          #"/home/me/Mega/System/Configurations/ngrok/ngrok.yml"
        ];
        tunnels = {
            #
        };
    };
}
