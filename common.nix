{ pkgs, ... }:
let
    theme = import ./components/theme.nix;
in {
    nix = {
        package = pkgs.nixVersions.latest;

        settings = {
            trusted-users = [ "root" "me" "@wheel" ];
            allowed-users = [ "root" "me" "@wheel" ];
            experimental-features = "nix-command";
            auto-optimise-store = true;
            max-jobs = "auto";
        };

        gc = {
            automatic = true;
            randomizedDelaySec = "14m";
            options = "--delete-older-than 2d";
            dates = "weekly";
        };
    };

    system.stateVersion = "25.11";
    time.timeZone = "America/Toronto";
    i18n = {
        defaultLocale = "en_CA.UTF-8";

        inputMethod = {
            enabled = "ibus";

            ibus.engines = with pkgs.ibus-engines; [
                libpinyin
                anthy
            ];
        };
    };

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
        ./components/system.nix
        ./components/nixpkgs.nix
        ./components/packages.nix
    ];
}
