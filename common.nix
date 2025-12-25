{ pkgs, ... }:
let
    theme = import ./components/theme.nix;
in {
#    system.rebuild.enableNg  = true;

    nix = {
        package = pkgs.nixVersions.latest;

        settings = {
            trusted-users = [ "root" "me" "@wheel" ];
            allowed-users = [ "root" "me" "@wheel" ];
            experimental-features = "nix-command";
#            experimental-features = "nix-command flakes";
            auto-optimise-store = true;
            max-jobs = "auto";
        };
    };

    system.stateVersion = "25.11";
    time.timeZone = "America/Toronto";
    i18n.defaultLocale = "en_CA.UTF-8";

    console = {
        earlySetup = true;
        keyMap = "us";
        font = "alt-8x16.gz";
        colors = theme.colors16;
    };


    documentation = {
        enable = true;
        man.enable = true;
        dev.enable = true;
    };

    qt.enable = true;
    qt.platformTheme = "kde";

    #
    # Configurations.
    #
    imports = [
        ./components/hardware.nix
        ./components/environment.nix
        ./components/fonts.nix
        ./components/networking.nix
        ./components/programs.nix
        ./components/security.nix
        ./components/services.nix
        ./components/users.nix
        ./components/xdg.nix
        ./components/nixpkgs.nix
        ./components/packages.nix
    ];
}
