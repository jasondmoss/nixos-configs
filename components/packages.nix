{ config, pkgs, lib, ... }:

let
    # --- Custom Package Definitions ---
    customPkgs = {
        gemini-wrapped = pkgs.callPackage ../custom-packages/gemini-cli/wrapper.nix {};
        gemini-nix     = pkgs.callPackage ../custom-packages/gemini-nix-assistant/default.nix {};
        gh-clone       = pkgs.callPackage ../custom-packages/gh-clone/default.nix {};
        gemini-desktop = pkgs.callPackage ../custom-packages/gemini-desktop/default.nix {};
        # kde-klassy   = pkgs.callPackage ../custom-packages/kde-klassy {};
        kde-darkly     = pkgs.callPackage ../custom-packages/kde-darkly {};
        nyxt-custom    = pkgs.callPackage ../custom-packages/nyxt-custom/default.nix { };
        proton-suite   = pkgs.callPackage ../custom-packages/proton-suite/default.nix {};
        strawberry     = pkgs.callPackage ../custom-packages/strawberry-master {};
        vivaldi        = pkgs.callPackage ../custom-packages/vivaldi-snapshot {};
        wavebox        = pkgs.callPackage ../custom-packages/wavebox-beta {};
    };

    # --- Package Categories ---
    pkgsByCategories = {
        nixos = with pkgs; [
            nixos-icons
            nixos-rebuild-ng
        ];

        development = with pkgs; [

            # Base Toolchain
            cargo
            rustc
            nodejs
            yarn
            gcc
            gdb
            gnumake
            ninja
            cmake
            pkg-config

            # KDE/Qt Specific Development
            extra-cmake-modules
            clazy
            gammaray
            heaptrack
            qtcreator
            valgrind

            # GNOME/GTK Development
            gtk4
            libadwaita
            glib-networking

            # IDEs & Tools
            phpstorm
            phpunit
            sublime4
            pre-commit
            cppcheck
        ];

        # New Category: KDE Plasma 6 & KF6 Core
        # Following Plasma 6.5+ and KF 6.20+ standards
        kde-plasma-core = with pkgs.kdePackages; [

            # Core Shell & Workspaces
            plasma-desktop
            plasma-workspace
            plasma5support # Essential for legacy widget compatibility in KF6
            plasma-wayland-protocols
            layer-shell-qt

            # System Integration
            baloo
            baloo-widgets
            bluedevil
            drkonqi
            kde-cli-tools
            kwallet
            kwallet-pam
            kwayland
            kwindowsystem
            networkmanager-qt
            modemmanager-qt

            # Theming & Assets
            breeze
            breeze-icons
            kiconthemes
            ksvg
            qtstyleplugin-kvantum

            # Qt 6 Base
            qtbase
            qtdeclarative
            qtsvg
            qttools
            wrapQtAppsHook
        ];

        kde-applications = with pkgs.kdePackages; [
            ark
            dolphin
            dolphin-plugins
            ffmpegthumbs
            ghostwriter
            isoimagewriter
            kate
            kcalc
            kdenlive
            kdevelop
            kompare
            krdc
            krdp
            ktorrent
            okular
            partitionmanager
            kdegraphics-thumbnailers
            kdesdk-thumbnailers
        ];

        kde-pim = with pkgs.kdePackages; [
            akonadi
            akonadi-calendar
            akonadi-calendar-tools
            akonadi-contacts
            akonadi-import-wizard
            akonadi-mime
            akonadi-search
            calendarsupport
            kitinerary
            ktrip
        ];

        gnome-stack = with pkgs; [
            nautilus
            gnome-tweaks
            gcolor3
            adwaita-icon-theme
            morewaita-icon-theme
        ];

        system-tools = with pkgs; [
            coreutils-full curl diffutils dysk fwupd fwupd-efi
            htop inetutils inxi killall lsd lshw nvme-cli pciutils
            smartmontools systemctl-tui usbutils wget git
        ];

        graphics-multimedia = with pkgs; [
            cairo
            ffmpeg-full
            ffmpegthumbnailer
            figma-linux
            imagemagick
            inkscape
            mpv-unwrapped
            mpvScripts.autosub
            mpvScripts.sponsorblock
            mpvScripts.uosc
            nomacs
            nvtopPackages.full
            pavucontrol
            vulkan-tools
            xnviewmp
        ];

        network-web = with pkgs; [
            filezilla firefox-nightly google-chrome links2 megasync
            megatools microsoft-edge mullvad-browser openvpn
            protonvpn-gui tor-browser
        ];

        theming-compat = with pkgs; [
            adwaita-qt6
            materia-kde-theme
            qadwaitadecorations-qt6
            comixcursors
            kdePackages.qt6ct
        ];

        custom = (builtins.attrValues customPkgs);
    };

in {
    imports = [
        ../custom-packages/firefox-stable
        ../custom-packages/gimp
        ../custom-packages/php
        ../custom-packages/vaapi
    ];

    # KDE exclude list.
    environment.plasma6.excludePackages = with pkgs.kdePackages; [
        elisa
        itinerary
    ];

    # GNOME exclude list.
    environment.gnome.excludePackages = with pkgs; [
        decibels
        geary
        gnome-calculator
        gnome-calendar
        gnome-console
        gnome-contacts
        gnome-maps
        gnome-music
        gnome-tour
        gnome-weather
    ];

    # Flatten the attribute set of lists into a single list.
    environment.systemPackages = lib.flatten (builtins.attrValues pkgsByCategories);
}

# <> #
