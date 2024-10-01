{ config, lib, pkgs, ... }:
let
    # Firefox Nightly desktop file.
    firefoxNightlyDesktopItem = pkgs.makeDesktopItem rec {
        type = "Application";
        terminal = false;
        name = "firefox-nightly";
        desktopName = "Firefox Nightly";
        exec = "firefox-nightly -P \"Nightly\" %u";
        icon = "/home/me/Mega/Images/Icons/Apps/firefox-developer-edition-alt.png";
        mimeTypes = [
            "application/pdf"
            "application/rdf+xml"
            "application/rss+xml"
            "application/xhtml+xml"
            "application/xhtml_xml"
            "application/xml"
            "image/gif"
            "image/jpeg"
            "image/png"
            "image/webp"
            "text/html"
            "text/xml"
            "x-scheme-handler/http"
            "x-scheme-handler/https"
        ];
        categories = [ "Network" "WebBrowser" ];
        actions = {
            NewWindow = {
                name = "Open a New Window";
                exec = "firefox-nightly -P \"Nightly\" --new-window %u";
            };
            NewPrivateWindow = {
                name = "Open a New Private Window";
                exec = "firefox-nightly -P \"Nightly\" --private-window %u";
            };
            ProfileSelect = {
                name = "Select a Profile";
                exec = "firefox-nightly --ProfileManager";
            };
        };
    };

    # Firefox Stable desktop file.
    firefoxStableDesktopItem = pkgs.makeDesktopItem rec {
        type = "Application";
        terminal = false;
        name = "firefox-stable";
        desktopName = "Firefox Stable";
        exec = "firefox-stable -P \"Default\" %u";
        icon = "/home/me/Mega/Images/Icons/Apps/firefox.png";
        mimeTypes = [
            "application/vnd.mozilla.xul+xml"
            "application/xhtml+xml"
            "text/html"
            "text/xml"
            "x-scheme-handler/ftp"
            "x-scheme-handler/http"
            "x-scheme-handler/https"
        ];
        categories = [ "Network" "WebBrowser" ];
        actions = {
            NewWindow = {
                name = "Open a New Window";
                exec = "firefox-stable -P \"Default\" --new-window %u";
            };
            NewPrivateWindow = {
                name = "Open a New Private Window";
                exec = "firefox-stable -P \"Default\" --private-window %u";
            };
            ProfileSelect = {
                name = "Select a Profile";
                exec = "firefox-stable --ProfileManager";
            };
        };
    };

    # Thunderbird desktop file.
    thunderbirdDesktopItem = pkgs.makeDesktopItem rec {
        type = "Application";
        terminal = false;
        name = "thunderbird";
        desktopName = "Thunderbird";
        exec = "thunderbird -P \"Me\"";
        icon = "/home/me/Mega/Images/Icons/Apps/thunderbird-daily.png";
        mimeTypes = [
            "message/rfc822"
            "x-scheme-handler/mailto"
        ];
        startupNotify = true;
        categories = [ "Application" "Network" "Email" ];
    };
in {
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
                "nvidia-x11"
                "nvidia-settings"
                "nvidia-persistenced"
                "nvidia-vaapi-driver"
                "vaapiVdpau"
            ];

            permittedInsecurePackages = [
                "openssl-1.1.1w"
            ];
        };

        # Mozilla Firefox Nightly overlay.
        overlays = [
            (import ../overlays/nixpkgs-mozilla/lib-overlay.nix)
            (import ../overlays/nixpkgs-mozilla/firefox-overlay.nix)
        ];
    };

    #-- CORE
    environment = {
        systemPackages = (with pkgs; [

            #-- CORE
            aha
            babl
            clinfo
            coreutils-full
            curl
            dwz
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
            vulkan-tools
            vulkan-validation-layers
            xdg-desktop-portal
            xdg-utils
            xorg.libxcb

            python312Full
            python312Packages.pyasyncore
            python312Packages.gyp
            python312Packages.pyqt6
            python312Packages.pytz

            #-- DESKTOP
            ly
            gtk4

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
            libunwind
            lua
            nodejs
            perl
            php83
            php84
            phpunit
            pre-commit
            rustc
            seer
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
            sublime4-dev

            #-- MULTIMEDIA
            faac
            ffmpeg
            ffmpegthumbnailer
            flac
            flacon
            fooyin
            isoimagewriter
            lame
            libcue
            libdrm
            mac
            mkcue
            mpg123
            mpv
            opusTools
            pavucontrol
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
            protonvpn-gui
            thunderbirdPackages.thunderbird-128
            zoom-us

            #-- MISCELLANEOUS / UTILITIES
            alacritty
            bitwarden
            conky
            libportal
            ulauncher
            wezterm

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
            kdeplasma-addons
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

        ]) ++ (with pkgs.php84Extensions; [

            #-- PHP 8.4
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

        ]) ++ (with pkgs; [

            #-- CUSTOM PACKAGE BUILDS.

            #-- Firefox Stable -- Rename executable
            (pkgs.runCommand "latest.firefox-bin" {
                preferLocalBuild = true;
            } ''
mkdir -p $out/bin
ln -s ${latest.firefox-bin}/bin/firefox $out/bin/firefox-stable
            '')

            #-- Firefox Stable -- Desktop Entry
            firefoxStableDesktopItem

            #-- Firefox Nightly (nixpkgs-mozilla) -- Rename executable
            (pkgs.runCommand "latest.firefox-nightly-bin" {
                preferLocalBuild = true;
            } ''
mkdir -p $out/bin
ln -s ${latest.firefox-nightly-bin}/bin/firefox-nightly $out/bin/firefox-nightly
            '')

            #-- Firefox Nightly -- Desktop Entry
            firefoxNightlyDesktopItem

            #-- Thunderbird -- Desktop Entry
            thunderbirdDesktopItem

            #-- Zen Browser
            # (pkgs.callPackage ../custom/zen-browser/default.nix {})

            #-- Conky
            # (pkgs.callPackage ../custom/conky/default.nix {})

            #-- GIMP Development
            # (pkgs.callPackage ../custom/gegl-devel/default.nix {})
            # (pkgs.callPackage ../custom/gimp-devel/default.nix {})

            #-- Klassy KDE Theme
            (pkgs.callPackage ../custom/klassy/default.nix {})

            #-- Strawberry Music Player
            (pkgs.callPackage ../custom/strawberry/default.nix {})

            #-- Ulauncher Beta
            # (pkgs.callPackage ../custom/ulauncher/default.nix {})

            #-- Wavebox Beta
            (pkgs.callPackage ../custom/wavebox/default.nix {})

            #-- Megasync
            # (pkgs.callPackage ../custom/megasync/default.nix {})

        ]);

    };

}
