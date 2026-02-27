{ pkgs, lib, ... }:

let
    # --- Custom Package Definitions ---
    customPkgs = {
        gemini-nix     = pkgs.callPackage ../custom-packages/gemini-nix-assistant {};
        gemini-wrapped = pkgs.callPackage ../custom-packages/gemini-cli/wrapper.nix {};
        gh-clone       = pkgs.callPackage ../custom-packages/gh-clone {};
        kde-darkly     = pkgs.callPackage ../custom-packages/kde-darkly {};
        kde-klassy     = pkgs.callPackage ../custom-packages/kde-klassy {};
        nyxt-custom    = pkgs.callPackage ../custom-packages/nyxt-custom { };
        strawberry     = pkgs.callPackage ../custom-packages/strawberry-master {};
        vivaldi        = pkgs.callPackage ../custom-packages/vivaldi-snapshot {};

        # Custom made applications.
        claude-ai      = pkgs.callPackage ../workshop/claude-ai {};
        feedbin-rss    = pkgs.callPackage ../workshop/feedbin-rss { };
        gemini-desktop = pkgs.callPackage ../workshop/gemini-desktop {};
        proton-suite   = pkgs.callPackage ../workshop/proton-suite {};
    };

    # --- Package Categories ---
    pkgsByCategories = {
        nixos = with pkgs; [
            nixos-icons
            nixos-rebuild-ng
            nix-prefetch-github
        ];

        system-tools = with pkgs; [
            coreutils-full
            curl
            diffutils
            dmidecode
            dysk
            fwupd
            fwupd-efi
            git
            htop
            inetutils
            inxi
            killall
            lsd
            lshw
            nvme-cli
            pciutils
            smartmontools
            systemctl-tui
            usbutils
            wget
        ];

        graphics-multimedia = with pkgs; [
            # Multimedia support.
            gst_all_1.gstreamer
            gst_all_1.gst-plugins-base
            gst_all_1.gst-plugins-good

            cairo
            ffmpeg-full
            ffmpegthumbnailer
            imagemagick
            inkscape
            mpv-unwrapped
            mpvScripts.autosub
            mpvScripts.sponsorblock
            mpvScripts.uosc
            nomacs
            nvtopPackages.full
            pavucontrol
            vorbis-tools
            vulkan-tools
            wayland-utils
            xnviewmp
        ];

        development = with pkgs; [
            # Base Toolchain
            cargo
            rustc
            nodejs
            yarn
            gcc
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

            # Android
            android-tools
        ];

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
            isoimagewriter
            kate
            kcalc
            kdbusaddons
            kdegraphics-thumbnailers
            kdenlive
            kdesdk-thumbnailers
            kdevelop
            kompare
            krdc
            krdp
            ksshaskpass
            ktorrent
            okular
            partitionmanager
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
        ];

        gnome-stack = with pkgs; [
            adwaita-icon-theme
            gcolor3
            gnome-tweaks
            morewaita-icon-theme
            nautilus
        ];

        network-web = with pkgs; [
            filezilla
            firefox-nightly
            google-chrome
            links2
            megatools
            microsoft-edge
            mullvad-browser
            openvpn
            protonvpn-gui
            tor-browser
        ];

        office = with pkgs; [
            libreoffice-qt-fresh
            notes
            standardnotes
        ];

        utilities = with pkgs; [
            conky
            rofi
            wezterm
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
