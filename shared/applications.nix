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
in
{
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

            permittedInsecurePackages = [
                "openssl-1.1.1w"  # Still not sure what is requiring this...
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
            expect
            flex
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
            pmutils
            pngquant
            psensor
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
            xdg-desktop-portal
            xdg-utils
            xorg.libxcb
            xorg.xrdb
            xrgears
            wmctrl

            python312Full
            python312Packages.pyasyncore
            python312Packages.gyp
            python312Packages.pyqt6
            python312Packages.pytz


            #-- GNOME DESKTOP
            #gtk3
            gtk4


            #-- KDE / PLASMA
            kdePackages.full
            kdePackages.qt6ct

            kdePackages.accounts-qt
            kdePackages.akonadi
            kdePackages.akonadi-calendar
            kdePackages.akonadi-calendar-tools
            kdePackages.akonadi-contacts
            kdePackages.akonadi-import-wizard
            kdePackages.akonadi-mime
            kdePackages.akonadi-notes
            kdePackages.akonadi-search
            kdePackages.ark
            kdePackages.dolphin
            kdePackages.dolphin-plugins
            kdePackages.frameworkintegration
            kdePackages.kate
            kdePackages.karchive
            kdePackages.kbreakout
            kdePackages.kcalc
            kdePackages.kcmutils
            kdePackages.kconfigwidgets
            kdePackages.kcoreaddons
            kdePackages.kdeconnect-kde
            kdePackages.kdecoration
            kdePackages.kdeplasma-addons
            kdePackages.kglobalaccel
            kdePackages.kglobalacceld
            kdePackages.kguiaddons
            kdePackages.kiconthemes
            kdePackages.kio
            kdePackages.kio-admin
            kdePackages.kio-extras
            kdePackages.kio-extras-kf5
            kdePackages.kio-fuse
            kdePackages.kio-gdrive
            kdePackages.kio-zeroconf
            kdePackages.kirigami
            kdePackages.kirigami-addons
            kdePackages.knotes
            kdePackages.ksshaskpass
            kdePackages.ksvg
            kdePackages.ktorrent
            kdePackages.kwallet
            kdePackages.kwallet-pam
            kdePackages.kwayland
            kdePackages.kwindowsystem
            kdePackages.layer-shell-qt
            kdePackages.modemmanager-qt
            kdePackages.networkmanager-qt
            kdePackages.okular
            kdePackages.plasma-browser-integration
            kdePackages.plasma-integration
            kdePackages.plasma-wayland-protocols
            kdePackages.plymouth-kcm
            kdePackages.qtstyleplugin-kvantum
            kdePackages.qtsvg
            kdePackages.qttools
            kdePackages.qtvirtualkeyboard
            kdePackages.wrapQtAppsHook
            kdePackages.xdg-desktop-portal-kde

            adwaita-qt6


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
            phpunit
            pre-commit
            rustc
            seer
            yarn

            php82
            php82Extensions.bz2
            php82Extensions.curl
            php82Extensions.fileinfo
            php82Extensions.gd
            php82Extensions.imagick
            php82Extensions.intl
            php82Extensions.mbstring
            php82Extensions.mysqlnd
            php82Extensions.pdo
            php82Extensions.pdo_dblib
            php82Extensions.pdo_mysql
            php82Extensions.pdo_odbc
            php82Extensions.tidy
            php82Extensions.xdebug
            php82Extensions.xml
            php82Extensions.xsl
            php82Extensions.zip
            php82Extensions.zlib

            php83
            php83Extensions.bz2
            php83Extensions.curl
            php83Extensions.fileinfo
            php83Extensions.gd
            php83Extensions.imagick
            php83Extensions.intl
            php83Extensions.mbstring
            php83Extensions.mysqlnd
            php83Extensions.pdo
            php83Extensions.pdo_dblib
            php83Extensions.pdo_mysql
            php83Extensions.pdo_odbc
            php83Extensions.tidy
            php83Extensions.xdebug
            php83Extensions.xml
            php83Extensions.xsl
            php83Extensions.zip
            php83Extensions.zlib

            # php83Packages.php-codesniffer
            # php83Packages.php-cs-fixer
            # php83Packages.phpmd
            # php83Packages.phpstan


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
            github-desktop
            inkscape
            nomacs
            nano
            onlyoffice-bin_latest
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
            chrome-gnome-shell
            megasync
            microsoft-edge
            thunderbirdPackages.thunderbird-128
            zoom-us

            #-- MISCELLANEOUS/UTILITIES
            alacritty
            bitwarden
            conky
            libportal
            protonmail-bridge
            protonmail-desktop
            protonvpn-cli
            protonvpn-gui
            ulauncher
            #wezterm

        ]) ++ (with pkgs; [

            #-- CUSTOM PACKAGE BUILDS.

            #-- Firefox Stable -- Rename executable
            (pkgs.runCommand "latest.firefox-bin" {
                preferLocalBuild = true;
            } ''
                mkdir -p $out/bin
                ln -s ${latest.firefox-bin}/bin/firefox $out/bin/firefox-stable
            '')
            firefoxStableDesktopItem

            #-- Firefox Nightly (nixpkgs-mozilla) -- Rename executable
            (pkgs.runCommand "latest.firefox-nightly-bin" {
                preferLocalBuild = true;
            } ''
                mkdir -p $out/bin
                ln -s ${latest.firefox-nightly-bin}/bin/firefox-nightly $out/bin/firefox-nightly
            '')
            firefoxNightlyDesktopItem

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

        ]);

    };

}
