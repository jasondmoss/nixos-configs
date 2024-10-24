{ lib, pkgs, ... }: {
    # Setup.
    nixpkgs = {
        hostPlatform = lib.mkDefault "x86_64-linux";

        config = {
            allowBroken = false;
            allowUnfree = true;

            packageOverrides = pkgs: {
                steam = pkgs.steam.override {
                    extraPkgs = pkgs: with pkgs; [
                        libgdiplus
                    ];
                };
            };

            allowUnfreePredicate = pkg: builtins.elem (pkgs.lib.getName pkg) [
                # "nvidia-x11"
                "nvidia-settings"
                "nvidia-persistenced"
                "nvidia-vaapi-driver"
                "vulkan-loader"
                "vulkan-tool"
                "vulkan-validation-layers"
            ];

            permittedInsecurePackages = [
                "openssl-1.1.1w"
            ];
        };

        overlays = [
            # Mozilla Firefox Nightly overlays.
            (import ../overlays/nixpkgs-mozilla/lib-overlay.nix)
            (import ../overlays/nixpkgs-mozilla/firefox-overlay.nix)
            # JetBrains EAP overlays.
            (import ../overlays/jetbrains/default.nix)
        ];
    };

    #-- Core Packages.
    environment = {
        systemPackages = (with pkgs; [

            aha
            babl
            clinfo
            coreutils-full
            curl
            dwz
            expat
            expect
            flex
            fontconfig
            fwupd
            fwupd-efi
            gcr
            gd
            gsasl
            htop
            inetutils
            inotify-tools
            killall
            libxfs
            libxml2
            links2
            linuxquota
            lm_sensors
            lsd
            lshw
            nix-du
            nix-index
            nix-prefetch-git
            nvme-cli
            openssl
            openvpn
            optipng
            pciutils
            pcre2
            pmutils
            pngquant
            rar
            smartmontools
            tldr
            unar
            unixtools.script
            unrar
            unzip
            usbutils
            wget
            wirelesstools
            xclip
            xfsprogs
            zip

            #-- GRAPHICS
            egl-wayland
            eglexternalplatform
            glxinfo
            gpm
            imagemagick
            jpegoptim
            jq
            libdrm
            libGL
            libglvnd
            libva
            libva-utils
            libva1
            mesa
            nvtopPackages.full
            virtualgl
            wayland-utils
            wmctrl
            # vulkan-tools
            # vulkan-validation-layers
            xdg-desktop-portal
            xdg-utils
            xorg.libxcb

            python312Full
            #python312Packages.pyasyncore
            #python312Packages.gyp
            #python312Packages.pyqt6
            #python312Packages.pytz

            #-- DESKTOP
            comixcursors
            gtk4
            ly

            #-- DEVELOPMENT
            bison
            bisoncpp
            bun
            cargo
            cmake
            cockpit
            ddev
            desktop-file-utils
            diffutils
            docker
            docker-client
            docker-compose
            eww
            extra-cmake-modules
            gcc
            gdb
            git
            go
            jetbrains.gateway
            jetbrains.jdk
            libunwind
            lua
            nodejs
            perl
            php83
            # php84
            phpunit
            pre-commit
            rustc
            seer
            superhtml
            yarn

            #-- SECURITY
            certbot
            chkrootkit
            encfs
            lynis
            mkcert
            sniffnet

            #-- EDITORS
            figma-linux
            gcolor3
            gegl
            gimp
            inkscape
            libreoffice-qt6-fresh
            nomacs
            nano
            phpstorm # Custom overlay.
            sublime4

            #-- MULTIMEDIA
            faac
            ffmpeg
            ffmpegthumbnailer
            flac
            flacon
            isoimagewriter
            lame
            libcue
            mac
            mkcue
            mpg123
            mpv
            mpvScripts.thumbfast
            opusTools
            pavucontrol
            qmmp
            shntool
            sox
            speechd
            vorbis-tools
            wavpack

            #-- INTERNET
            brave
            filezilla
            google-chrome
            megasync
            megatools
            microsoft-edge
            opera
            protonvpn-gui
            thunderbirdPackages.thunderbird-128
            zoom-us

            #-- MISCELLANEOUS / UTILITIES
            alacritty
            conky
            libportal
            ulauncher
            wezterm

            (chromium.override {
                enableWideVine = true;
            })


            #-- CUSTOM PACKAGES

            #-- Anytype
            (pkgs.callPackage ../packages/anytype {})

            # Conky
            # (pkgs.callPackage ../packages/conky {})

            # GIMP Development
            # (pkgs.callPackage ../packages/gegl-devel {})
            # (pkgs.callPackage ../packages/gimp-devel {})

            # Klassy KDE Theme
            (pkgs.callPackage ../packages/klassy {})

            # Strawberry Music Player
            (pkgs.callPackage ../packages/strawberry {})

            # Wavebox Beta
            (pkgs.callPackage ../packages/wavebox {})

        ]) ++ (with pkgs.kdePackages; [

            #-- KDE
            full
            qt6ct
            accounts-qt
            akonadi
            akonadi-calendar
            akonadi-calendar-tools
            akonadi-contacts
            akonadi-import-wizard
            akonadi-mime
            akonadi-notes
            akonadi-search
            ark
            dolphin
            dolphin-plugins
            ffmpegthumbs
            frameworkintegration
            kate
            karchive
            kbreakout
            kcalc
            kcmutils
            kconfigwidgets
            kcoreaddons
            kde-cli-tools
            kdeconnect-kde
            kdecoration
            kdegraphics-thumbnailers
            kdeplasma-addons
            kdesdk-thumbnailers
            kglobalaccel
            kglobalacceld
            kguiaddons
            kiconthemes
            kio
            kio-admin
            kio-extras
            kio-extras-kf5
            kio-fuse
            kio-gdrive
            kio-zeroconf
            kirigami
            kirigami-addons
            ksshaskpass
            ksvg
            ktorrent
            kwallet
            kwallet-pam
            kwayland
            kwindowsystem
            layer-shell-qt
            modemmanager-qt
            networkmanager-qt
            okular
            partitionmanager
            plasma-browser-integration
            plasma-integration
            plasma-wayland-protocols
            plymouth-kcm
            qtstyleplugin-kvantum
            qtsvg
            qttools
            taglib
            wayland
            wayland-protocols
            wrapQtAppsHook
            xdg-desktop-portal-kde

        ]) ++ (with pkgs.php83Extensions; [

            #-- PHP 8.3
            bz2
            curl
            fileinfo
            gd
            imagick
            intl
            mbstring
            mysqlnd
            pdo
            pdo_dblib
            pdo_mysql
            pdo_odbc
            tidy
            xml
            xsl
            zip
            zlib

        # ]) ++ (with pkgs.php84Extensions; [

            # #-- PHP 8.4
            # bz2
            # curl
            # fileinfo
            # gd
            # imagick
            # intl
            # mbstring
            # mysqlnd
            # pdo
            # pdo_dblib
            # pdo_mysql
            # pdo_odbc
            # tidy
            # xml
            # xsl
            # zip
            # zlib

        ]);

    };

    # Desktop Entries.
    imports = [
        ./desktop-entries/firefox-nightly.nix
        ./desktop-entries/firefox-stable.nix
        ./desktop-entries/thunderbird.nix
        ./desktop-entries/google-chrome-stable.nix
    ];
}
