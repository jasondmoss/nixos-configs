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
                "electron-25.9.0"
                "openssl-1.1.1w"
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
            xfsprogs
            zip

            #-- GRAPHICS
            egl-wayland
            imagemagick
            jpegoptim
            jq
            libglvnd
            libva
            libva-utils
            libva1
            nvtop
            virtualgl
            # vkdt-wayland
            vulkan-caps-viewer
            vulkan-extension-layer
            vulkan-tools
            vulkan-utility-libraries
            vulkan-validation-layers
            wayland-utils
            xdg-utils
            xorg.libxcb
            xorg.xrdb
            xrgears

            #-- GNOME/GTK
            gtk3
            gtk4
            libcanberra-gtk3
            xdg-desktop-portal
            xdg-desktop-portal-gnome
            xdg-desktop-portal-gtk
            xdg-desktop-portal-wlr
            gnome.gnome-tweaks
            gnome.nautilus

            #-- KDE/PLASMA
            libsForQt5.ark
            # libsForQt5.breeze-qt5
            libsForQt5.clip
            libsForQt5.dolphin-plugins
            # libsForQt5.flatpak-kcm
            libsForQt5.kaddressbook
            libsForQt5.kate
            libsForQt5.kcalc
            libsForQt5.kcoreaddons
            # libsForQt5.kdeconnect-kde
            libsForQt5.kdeplasma-addons
            # libsForQt5.kmail
            # libsForQt5.kmail-account-wizard
            # libsForQt5.kmailtransport
            libsForQt5.ksshaskpass
            libsForQt5.ktorrent
            libsForQt5.kwallet
            libsForQt5.kwallet-pam
            libsForQt5.okular
            libsForQt5.plasma-browser-integration
            libsForQt5.plasma-wayland-protocols
            libsForQt5.qt5ct
            libsForQt5.qtstyleplugins
            libsForQt5.sddm-kcm
            libsForQt5.xdg-desktop-portal-kde

            qt6.full
            qt6.qmake
            qt6.qt5compat
            qt6.qtbase
            qt6.qtcharts
            qt6.qtconnectivity
            qt6.qtdatavis3d
            qt6.qtdeclarative
            qt6.qtdoc
            qt6.qtgraphs
            qt6.qtgrpc
            qt6.qthttpserver
            qt6.qtimageformats
            qt6.qtlanguageserver
            qt6.qtlocation
            qt6.qtlottie
            qt6.qtmqtt
            qt6.qtmultimedia
            qt6.qtnetworkauth
            qt6.qtpositioning
            qt6.qtquick3d
            qt6.qtquick3dphysics
            qt6.qtquickeffectmaker
            qt6.qtquicktimeline
            qt6.qtremoteobjects
            qt6.qtscxml
            qt6.qtsensors
            qt6.qtserialbus
            qt6.qtserialport
            qt6.qtshadertools
            qt6.qtspeech
            qt6.qtsvg
            qt6.qttools
            qt6.qttranslations
            qt6.qtvirtualkeyboard
            qt6.qtwayland
            qt6.qtwebchannel
            qt6.qtwebengine
            qt6.qtwebsockets
            qt6.qtwebview
            qt6.wrapQtAppsHook

            qt6Packages.appstream-qt
            qt6Packages.futuresql
            qt6Packages.kdsoap
            qt6Packages.kquickimageedit
            qt6Packages.libqaccessibilityclient
            qt6Packages.libquotient
            qt6Packages.mlt
            qt6Packages.packagekit-qt
            qt6Packages.poppler
            qt6Packages.qca
            qt6Packages.qcoro
            qt6Packages.qgpgme
            qt6Packages.qscintilla
            qt6Packages.qt6ct
            qt6Packages.qt6gtk2
            qt6Packages.qtforkawesome
            qt6Packages.qtkeychain
            qt6Packages.qtpbfimageplugin
            qt6Packages.qtstyleplugin-kvantum
            qt6Packages.qtutilities
            qt6Packages.quazip
            qt6Packages.qwlroots
            qt6Packages.qxlsx
            qt6Packages.qzxing
            qt6Packages.sddm
            qt6Packages.waylib
            qt6Packages.wayqt

            lightly-qt

            # python310Packages.gyp
            # python310Packages.pyqt6
            python311Packages.gyp
            python311Packages.pyqt6
            python311Packages.pytz

            # ksmoothdock

            #-- LabWC
            # labwc
            # lemurs
            # kanshi
            # mako
            # swaybg
            # waybar
            # wmctrl

            #-- THEMING
            adwaita-qt6
            adapta-kde-theme
            adementary-theme
            arc-kde-theme
            ayu-theme-gtk
            hicolor-icon-theme
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
            diffutils
            docker
            docker-client
            eww
            gcc
            gdb
            # ggshield
            git
            go
            lua
            nodejs
            perl
            pre-commit
            rustc
            seer
            yarn

            php81
            php81Extensions.bz2
            php81Extensions.curl
            php81Extensions.fileinfo
            php81Extensions.gd
            php81Extensions.imagick
            php81Extensions.intl
            php81Extensions.mbstring
            php81Extensions.mysqlnd
            php81Extensions.pdo
            php81Extensions.pdo_dblib
            php81Extensions.pdo_mysql
            php81Extensions.pdo_odbc
            php81Extensions.tidy
            php81Extensions.xdebug
            php81Extensions.xml
            php81Extensions.xsl
            php81Extensions.zip
            php81Extensions.zlib

            php81Packages.php-cs-fixer
            php81Packages.phpcbf
            php81Packages.phpcs
            php81Packages.phpmd
            php81Packages.phpstan

            #-- SECURITY
            chkrootkit
            encfs
            lynis
            mkcert
            sniffnet

            #-- EDITORS
            # bcompare
            darktable
            gcolor3
            gimp
            inkscape
            libreoffice-qt
            # masterpdfeditor4
            nomacs
            nano
            retext
            sublime4-dev
            vim

            #-- MULTIMEDIA
            # aaxtomp3
            audacity
            audible-cli
            cuetools
            easytag
            faac
            ffmpeg
            ffmpegthumbnailer
            flac
            flacon
            isoimagewriter
            lame
            libcue
            libdrm
            mac
            mkcue
            mpg123
            mpg321
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
            opera
            steam
            tor-browser-bundle-bin
            vivaldi
            zoom-us

            #-- MISCELLANEOUS/UTILITIES
            bitwarden
            libportal
            protonmail-bridge
            protonvpn-cli
            protonvpn-gui
            qemu
            ulauncher
            wezterm

        ] ++ [

            #
            #    CUSTOM PACKAGE BUILDS.
            #

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
            # XDG_SESSION_TYPE="wayland";
            XDG_CURRENT_DESKTOP="KDE";
            # XDG_CURRENT_DESKTOP="wlroots";
            XCURSOR_THEME="ComixCursors";
            DEFAULT_BROWSER="/run/current-system/sw/bin/firefox-nightly";

            GST_PLUGIN_SYSTEM_PATH_1_0=lib.makeSearchPathOutput "lib" "lib/gstreamer-1.0" [
                pkgs.gst_all_1.gst-editing-services
                pkgs.gst_all_1.gst-libav
                pkgs.gst_all_1.gst-plugins-bad
                pkgs.gst_all_1.gst-plugins-base
                pkgs.gst_all_1.gst-plugins-good
                pkgs.gst_all_1.gst-plugins-ugly
                pkgs.gst_all_1.gstreamer
            ];

            ## -- WAYLAND
            # MOZ_ENABLE_WAYLAND="1";
            # NIXOS_OZONE_WL="1";
            # QT_QPA_PLATFORM="wayland;xcb";
            # GBM_BACKEND="nvidia-drm";
            # __GLX_VENDOR_LIBRARY_NAME="nvidia";
            ENABLE_VKBASALT="1";
            # LIBVA_DRIVER_NAME="nvidia";
            # QT_WAYLAND_DISABLE_WINDOWDECORATION="1";
            # WLR_NO_HARDWARE_CURSORS="1";
            # SDL_VIDEODRIVER="wayland";
            # _JAVA_AWT_WM_NONREPARENTING="1"; # For JetBrains
        };
    };

}
