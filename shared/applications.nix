{ config, lib, pkgs, ... }:
let
    # Firefox Nightly
    firefoxNightlyDesktopItem = pkgs.makeDesktopItem rec {
       type = "Application";
       terminal = false;
       name = "Firefox Nightly";
       desktopName = "Firefox Nightly";
       exec = "$out/bin/firefox-nightly -P \"Nightly\" %u";
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

    # Firefox Stable
    firefoxStableDesktopItem = pkgs.makeDesktopItem rec {
        type = "Application";
        terminal = false;
        name = "Firefox Stable";
        desktopName = "Firefox Stable";
        exec = "$out/bin/firefox-stable -P \"Default\" %u";
        icon = "firefox";
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
in {
    nixpkgs = {
        hostPlatform = lib.mkDefault "x86_64-linux";

        config = {
            allowBroken = false;
            allowUnfree = true;

            firefox.enablePlasmaBrowserIntegration = true;

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
            coreutils-full
            curl
            expect
            flex
            fwupd
            fwupd-efi
            gcr
            gd
            gsasl
            inetutils
            inotify-tools
            killall
            libxml2
            links2
            lm_sensors
            nix-du
            nix-index
            nix-prefetch-git
            openssl
            openvpn
            optipng
            pciutils
            pmutils
            pngquant
            psensor
            tldr
            unixtools.script
            usbutils
            wget

            #-- CORE UTILS
            clinfo
            htop
            libxfs
            lsd
            nvme-cli
            rar
            smartmontools
            unar
            unrar
            unzip
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
            php83Extensions.pdo_mysql
            php82Extensions.pdo_odbc
            php82Extensions.tidy
            php82Extensions.xml
            php82Extensions.xsl
            php82Extensions.zip
            php82Extensions.zlib

            php82Packages.php-cs-fixer
            php82Packages.phpcbf
            php82Packages.phpcs
            php82Packages.phpmd
            php82Packages.phpstan

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
            megasync
            microsoft-edge
            steam
            tor-browser-bundle-bin
            zoom-us

            #-- MISCELLANEOUS/UTILITIES
            bitwarden
            conky
            #flatpak
            #flatpak-builder
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

            #-- Firefox Nightly (nixpkgs-mozilla)
            (pkgs.runCommand "firefox-nightly" {
               preferLocalBuild = true;
            } ''
               mkdir -p $out/bin
               ln -s ${latest.firefox-nightly-bin}/bin/firefox $out/bin/firefox-nightly
            '')
            firefoxNightlyDesktopItem

            #-- Firefox Stable
            (pkgs.runCommand "firefox-stable" {
                preferLocalBuild = true;
            } ''
                mkdir -p $out/bin
                ln -s ${pkgs.firefox}/bin/firefox $out/bin/firefox-stable
            '')
            firefoxStableDesktopItem

            (pkgs.writeShellScriptBin "qemu-system-x86_64-uefi" ''
                qemu-system-x86_64 \
                -bios ${pkgs.OVMF.fd}/FV/OVMF.fd \
                "$@"
            '')

            #
            # --------------
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

        ];

        sessionVariables = {
            DEFAULT_BROWSER = "${pkgs.latest.firefox-nightly-bin}/bin/firefox-nightly -P 'Nightly'";
            MOZ_ENABLE_WAYLAND = "1";
            NIXOS_OZONE_WL = "1";
            GST_PLUGIN_SYSTEM_PATH_1_0 = lib.makeSearchPathOutput "lib" "lib/gstreamer-1.0" [
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
