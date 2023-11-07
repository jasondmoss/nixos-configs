{ config, lib, pkgs, ... }:
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
                "openssl-1.1.1w"
                "qtwebkit-5.212.0-alpha4"
            ];
        };

        overlays = [
            (import ./overlays/nixpkgs-mozilla/lib-overlay.nix)
            (import ./overlays/nixpkgs-mozilla/firefox-overlay.nix)
        ];
    };

    environment = {
        systemPackages = with pkgs; [

            #-- CORE
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
            lm_sensors
            lsd
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
            xfsprogs
            zip

            #-- GRAPHICS
            egl-wayland
            imagemagick
            jpegoptim
            jq
            libva
            libva-minimal
            libva-utils
            libva1
            libva1-minimal
            wayland
            xdg-utils

            #-- GNOME/GTK
            gtk3 gtk3-x11
            gtk4
            xdg-desktop-portal
            xdg-desktop-portal-gnome
            xdg-desktop-portal-gtk
            gnome.gnome-tweaks

            #-- KDE/PLASMA
            libsForQt5.ark
            libsForQt5.clip
            libsForQt5.dolphin-plugins
            libsForQt5.flatpak-kcm
            libsForQt5.kate
            libsForQt5.kcalc
            libsForQt5.kdeplasma-addons
            libsForQt5.kcoreaddons
            libsForQt5.ksshaskpass
            libsForQt5.ktorrent
            libsForQt5.kwallet
            libsForQt5.kwallet-pam
            libsForQt5.plasma-browser-integration
            libsForQt5.qtstyleplugins
            libsForQt5.sddm-kcm
            libsForQt5.xdg-desktop-portal-kde

            qt6.full
            qt6Packages.qt6ct
            qt6Packages.qt6gtk2
            qt6Packages.qtkeychain
            qt6Packages.qtstyleplugin-kvantum
            qt6Packages.quazip
            qt6Packages.qscintilla
            qt6Packages.poppler

            python310Packages.pyqt6
            python311Packages.pyqt6
            python311Packages.pytz

            ksmoothdock

            #-- THEMING
            adwaita-qt6
            adapta-kde-theme
            adementary-theme
            arc-kde-theme
            ayu-theme-gtk
            materia-kde-theme

            gnome.adwaita-icon-theme
            gnome-icon-theme
            pantheon.elementary-icon-theme

            #-- DEVELOPMENT
            bison
            bisoncpp
            bun
            cargo
            cmake
            cockpit
            ddev
            desktop-file-utils
            eww
            gcc
            gdb
            ggshield
            git
            go
            lua
            nodejs
            perl
            pre-commit
            rustc
            seer
            yarn

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

            php83Packages.php-cs-fixer
            php83Packages.phpcbf
            php83Packages.phpcs
            php83Packages.phpmd
            # php83Packages.phpstan

            #-- SECURITY
            chkrootkit
            encfs
            lynis
            mkcert
            sniffnet

            #-- EDITORS
            bcompare
            darktable
            emem
            gcolor3
            gimp
            inkscape
            jetbrains-toolbox
            krita
            libreoffice-qt
            masterpdfeditor4
            nomacs
            nano
            retext
            standardnotes
            sublime4-dev
            vim

            #-- MULTIMEDIA
            ffmpeg
            ffmpegthumbnailer
            libdrm
            mpg321
            speechd

            aaxtomp3
            audacity
            audible-cli
            easytag
            flacon
            isoimagewriter
            mpv
            pavucontrol

            #-- INTERNET
            element-desktop # Matrix client
            filezilla
            google-chrome
            chrome-gnome-shell
            latest.firefox-bin
            latest.firefox-nightly-bin
            megasync
            microsoft-edge
            steam
            thunderbird-bin
            tor-browser-bundle-bin
            zoom-us

            #-- MISCELLANEOUS/UTILITIES
            bitwarden
            conky
            libportal
            protonmail-bridge
            protonvpn-cli
            protonvpn-gui
            qemu
            sticky
            ulauncher
            wezterm

        ] ++ [

            #
            #    CUSTOM PACKAGE BUILDS.
            #

            #-- Anytype
            (pkgs.callPackage ./pkgs/anytype/default.nix {})

            #-- GIMP Development
            # (pkgs.callPackage ./pkgs/gegl-devel/default.nix {})
            # (pkgs.callPackage ./pkgs/gimp-devel/default.nix {})

            #-- Klassy KDE Theme
            (pkgs.libsForQt5.callPackage ./pkgs/klassy/default.nix {})

            #-- Master PDF 5
            # (pkgs.libsForQt5.callPackage ./pkgs/masterpdf5/default.nix {})

            #-- Standard Notes
            (pkgs.callPackage ./pkgs/standardnotes/default.nix {})

            #-- Strawberry Music Player
            (pkgs.callPackage ./pkgs/strawberry/default.nix {})

            #-- Wavebox Beta
            (pkgs.callPackage ./pkgs/wavebox/default.nix {})

            #
            # --------------
            #

            (pkgs.writeShellScriptBin "qemu-system-x86_64-uefi" ''
qemu-system-x86_64 -bios ${pkgs.OVMF.fd}/FV/OVMF.fd "$@"
            '')

        ];

        sessionVariables = {
            DEFAULT_BROWSER="/run/current-system/sw/bin/firefox-nightly -P 'Nightly'";
            MOZ_ENABLE_WAYLAND="1";
            NIXOS_OZONE_WL="1";
            GST_PLUGIN_SYSTEM_PATH_1_0=lib.makeSearchPathOutput "lib" "lib/gstreamer-1.0" [
                pkgs.gst_all_1.gst-editing-services
                pkgs.gst_all_1.gst-libav
                pkgs.gst_all_1.gst-plugins-bad
                pkgs.gst_all_1.gst-plugins-base
                pkgs.gst_all_1.gst-plugins-good
                pkgs.gst_all_1.gst-plugins-ugly
                pkgs.gst_all_1.gstreamer
            ];
        };

    };

}
