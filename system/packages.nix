{ pkgs, lib, ... }:

let
    # --- Custom Package Definitions ---
    customPkgs = {
        clate          = pkgs.callPackage ../packages/clate {};
        claude-code    = pkgs.callPackage ../packages/claude-code {};
        claude-desktop = pkgs.callPackage ../packages/claude-desktop {};
        gh-clone       = pkgs.callPackage ../packages/gh-clone {};
        jopdf          = pkgs.callPackage ../packages/jopdf {};
        kde-darkly     = pkgs.callPackage ../packages/kde-darkly {};
        #kde-klassy     = pkgs.callPackage ../packages/kde-klassy {};
        #kde-vinyl      = pkgs.callPackage ../packages/kde-vinyl {};
        krema          = pkgs.kdePackages.callPackage ../packages/krema {};
        nyxt-custom    = pkgs.callPackage ../packages/nyxt-custom { };
        #sddm-persev    = pkgs.callPackage ../packages/sddm-perseverance {};
        stage-manager  = pkgs.callPackage ../packages/stage-manager {};
        standardnotes  = pkgs.callPackage ../packages/standardnotes {};
        strawberry     = pkgs.callPackage ../packages/strawberry-master {};
        symbolic-cal   = pkgs.callPackage ../packages/symbolic-calendar {};
        system-panel   = pkgs.callPackage ../packages/system-panel {};
        vivaldi        = pkgs.callPackage ../packages/vivaldi-snapshot {
            # Custom package: nothing wires NIXOS_OZONE_WL in, so force ozone
            # Wayland here or Vivaldi silently runs on XWayland.
            commandLineArgs = "--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations";
        };
        wavebox        = pkgs.callPackage ../packages/wavebox-beta {};
    };

    # --- System Python ---
    # One declared interpreter for shebangs, one-liners, Claude Code sessions
    # and PhpStorm's Python Portable plugin (exposed at /etc/jetbrains/python
    # below).
    systemPython = pkgs.python3.withPackages (p: [ p.cryptography p.pip ]);

    # --- Package Categories ---
    pkgsByCategories = {
        nixos = with pkgs; [
            fastfetch
            nixos-icons
            nix-prefetch-github
        ];

        system-tools = with pkgs; [
            btrfs-progs
            coreutils-full
            curl
            diffutils
            dmidecode
            dysk
            htop
            inetutils
            inxi
            jq
            killall
            lm_sensors
            lsd
            lshw
            nvme-cli
            pciutils
            smartmontools
            stressapptest
            systemctl-tui
            usbutils
            wget
        ];

        graphics-multimedia = with pkgs; [
            # Multimedia support.
            gst_all_1.gstreamer
            gst_all_1.gst-plugins-base
            gst_all_1.gst-plugins-good

            audacity_3
            #audacity
            cuetools
            easytag
            ffmpeg-full
            figma-linux
            flacon
            imagemagick
            inkscape
            (mpv.override { scripts = with mpvScripts; [ sponsorblock uosc ]; })
            nomacs
            nvtopPackages.full
            pavucontrol
            realesrgan-ncnn-vulkan # Vulkan upscaler (`enlarge` shell function)
            shotcut
            vorbis-tools
            vulkan-tools
            wayland-utils

            # MKVToolNix
            mkvtoolnix
        ];

        development = with pkgs; [
            # Base Toolchain
            cargo
            cmake
            ddev
            gcc
            gh
            git
            gnumake
            mkcert
            ninja
            nodejs
            pkg-config
            rustc
            yarn

            # Python — the declared env from the let block above
            systemPython

            # KDE/Qt Specific Development
            clazy
            gammaray
            heaptrack
            qtcreator
            valgrind

            # GNOME/GTK Development
            glib-networking

            # IDEs & Tools
            cppcheck
            phpstorm
            sublime4-dev

            # PHP Quality Tools
            php83                # host PHP CLI: PhpStorm interpreter + runs project-local vendor/bin tools
            phpPackages.php-codesniffer # phpcs + phpcbf
            phpPackages.php-cs-fixer    # php-cs-fixer
            phpstan               # static analysis

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
            ksvg

            # Qt 6 Base
            qtbase
            qtdeclarative
            qtsvg
            qttools
            qtwebengine
        ];

        kde-applications = with pkgs.kdePackages; [
            ark
            dolphin
            dolphin-plugins
            filelight
            ffmpegthumbs
            kate
            kcalc
            kdbusaddons
            kdegraphics-thumbnailers
            kdesdk-thumbnailers
            krdp
            ksshaskpass
            okular
            partitionmanager
        ];

        gnome-stack = with pkgs; [
            adwaita-icon-theme
            gcolor3
            nautilus
        ];

        network-web = with pkgs; [
            filezilla
            firefox-nightly
            google-chrome
            microsoft-edge
            mullvad-browser
            proton-vpn
            tor-browser
            unclutter
        ];

        office = with pkgs; [
            libreoffice-qt-stable
        ];

        utilities = with pkgs; [
            fuzzel
            hyprpicker # `hp` colour picker (with fuzzel + wl-copy)
            libnotify
            p7zip-rar
            pandoc
            python3Packages.weasyprint
            rar
            unrar
            unzip
            wezterm
            wl-clipboard
        ];

        theming-compat = with pkgs; [
            comixcursors
        ];

        custom = (builtins.attrValues customPkgs);
    };
in {
    imports = [
        ../packages/claude-code-browser
        ../packages/gps-signature
        ../packages/gimp
    ];

    # KDE exclude list.
    environment.plasma6.excludePackages = with pkgs.kdePackages; [
        discover
        elisa
        itinerary
        khelpcenter
        plasma-browser-integration
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

    # PhpStorm's Python Portable plugin takes an interpreter *folder*
    # (anything with bin/python3) and stores that path, so hand it a
    # symlink that follows rebuilds instead of a raw /nix/store path.
    # Settings ▸ Python Portable ▸ Add from Disk… → /etc/jetbrains/python
    environment.etc."jetbrains/python".source = systemPython;
}

# <> #
