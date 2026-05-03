################################################################################
 ##                                                                          ##
 ##                             ·: ATREIDES :·                               ##
 ##                                                                          ##
 ##          NixOS 25.11                                                     ##
 ##          AMD Ryzen 9 3900X                                               ##
 ##          NVIDIA RTX 2060 -- 32 GiB RAM                                   ##
 ##          KDE Plasma 6                                                    ##
 ##          Wayland                                                         ##
 ##                                                                          ##
################################################################################

{ pkgs, ... }:
let
    identity = import ./identity.nix;
    theme = import ./desktop/theme.nix;
in {
    nix = {
        package = pkgs.nixVersions.latest;

        settings = {
            trusted-users = [ "root" identity.userHandle "@wheel" ];
            allowed-users = [ "root" identity.userHandle "@wheel" ];
            experimental-features = "nix-command";
            auto-optimise-store = true;
            max-jobs = "auto";
            system-features = [
                "benchmark"
                "big-parallel"
                "kvm"
                "nixos-test"
                "gccarch-znver2"
            ];
        };

        gc = {
            automatic = true;
            randomizedDelaySec = "14m";
            options = "--delete-older-than 2d";
            dates = "weekly";
        };
    };

    networking.hostName = "atreides";
    system.stateVersion = "25.11";
    time.timeZone = "America/Toronto";

    i18n = {
        defaultLocale = "en_CA.UTF-8";

        inputMethod = {
            enable = true;
            type = "fcitx5";

            fcitx5 = {
                waylandFrontend = true;

                addons = with pkgs; [
                    fcitx5-gtk
                    qt6Packages.fcitx5-chinese-addons
                    kdePackages.fcitx5-configtool
                ];
            };
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

    #
    # Configurations.
    #
    imports = [
        ./nixpkgs.nix

        # Hardware.
        ./hardware/boot.nix
        ./hardware/gpu.nix
        ./hardware/peripherals.nix
        ./hardware/power.nix

        # Desktop.
        ./desktop/plasma.nix
        ./desktop/fonts.nix

        # System.
        ./networking.nix
        ./security.nix
        ./users.nix
        ./environment.nix
        ./programs.nix
        ./packages.nix
        ./services.nix

        # Development & AI.
        ./development.nix
        ./ai.nix
    ];
}

# <> #
