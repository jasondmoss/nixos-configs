{ pkgs, lib, ... }:

let
    # Ferrite requires Rust ≥ 1.92; NixOS 25.11 ships 1.91.1.
    # Pull just the compiler/cargo from nixpkgs-unstable; build inputs stay on stable.
    unstable = import /nix/var/nix/profiles/per-user/root/channels/nixpkgs {
        config = pkgs.config;
    };
    ferriteRustPlatform = pkgs.makeRustPlatform {
        cargo = unstable.cargo;
        rustc = unstable.rustc;
    };

    # --- Custom Package Definitions ---
    customPkgs = {
        audacity-beta  = pkgs.callPackage ./packages/audacity-beta {};
        ferrite        = pkgs.callPackage ./packages/ferrite { rustPlatform = ferriteRustPlatform; };
        gemini-nix     = pkgs.callPackage ./packages/gemini-nix-assistant {};
        gemini-wrapped = pkgs.callPackage ./packages/gemini-cli/wrapper.nix {};
        gh-clone       = pkgs.callPackage ./packages/gh-clone {};
        kde-darkly     = pkgs.callPackage ./packages/kde-darkly {};
        kde-klassy     = pkgs.callPackage ./packages/kde-klassy {};
        nyxt-custom    = pkgs.callPackage ./packages/nyxt-custom { };
        qstickynotes   = pkgs.callPackage ./packages/qstickynotes {};
        strawberry     = pkgs.callPackage ./packages/strawberry-master {};
        vivaldi        = pkgs.callPackage ./packages/vivaldi-snapshot {};
        wavebox        = pkgs.callPackage ./packages/wavebox-beta {};

        # Custom workshop applications.
        #plasma-dock      = pkgs.callPackage ./workshop/plasma-dock {};
    };

    # --- Package Categories ---
    pkgsByCategories = {
        nixos = with pkgs; [
            fastfetch
            nixos-icons
            nixos-rebuild-ng
            nix-prefetch-github
            nh
        ];

        system-tools = with pkgs; [
            btrfs-progs
            coreutils-full
            curl
            diffutils
            dmidecode
            dysk
            fwupd
            fwupd-efi
            htop
            inetutils
            inxi
            killall
            lm_sensors
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

            audacity
            cairo
            cuetools
            easytag
            ffmpeg-full
            ffmpegthumbnailer
            figma-linux
            flacon
            imagemagick
            inkscape
            mpv-unwrapped
            mpvScripts.autosub
            mpvScripts.sponsorblock
            mpvScripts.uosc
            nomacs
            nvtopPackages.full
            pavucontrol
            photoprism
            shotcut
            taglib-sharp
            taglib_extras
            vorbis-tools
            vulkan-tools
            wayland-utils
            xnviewmp

            # MKVToolNix
            mkvtoolnix
        ];

        development = with pkgs; [
            # Base Toolchain
            cargo
            cmake
            ddev
            gcc
            git
            gnumake
            mkcert
            ninja
            nodejs
            pkg-config
            rustc
            yarn

            # KDE/Qt Specific Development
            clazy
            gammaray
            heaptrack
            qtcreator
            valgrind

            # GNOME/GTK Development
            glib-networking
            gtk4
            libadwaita

            # IDEs & Tools
            cppcheck
            phpstorm
            phpunit
            pre-commit
            sublime4

            # Android
            android-tools
        ];

        kde-plasma-core = with pkgs.kdePackages; [
            extra-cmake-modules

            # Core Shell & Workspaces
            layer-shell-qt
            plasma-desktop
            plasma-wayland-protocols
            plasma-workspace
            plasma5support

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
            modemmanager-qt
            networkmanager-qt

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
        ];

        kde-applications = with pkgs.kdePackages; [
            ark
            dolphin
            dolphin-plugins
            filelight
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
            proton-vpn
            qbittorrent
            tor-browser
        ];

        office = with pkgs; [
            libreoffice-qt-fresh
            notes
            #standardnotes
        ];

        utilities = with pkgs; [
            conky
            fuzzel
            p7zip-rar
            pandoc
            quickemu
            rar
            unrar
            unzip
            wezterm
        ];

        theming-compat = with pkgs; [
            adwaita-qt6
            comixcursors
            kdePackages.qt6ct
            materia-kde-theme
            qadwaitadecorations-qt6
        ];

        custom = (builtins.attrValues customPkgs);
    };
in {
    imports = [
        ./packages/firefox-stable
        ./packages/gimp
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
