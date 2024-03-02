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
                "freeimage-unstable-2021-11-01"
                "openssl-1.1.1w"
            ];
        };

        # Mozilla Firefox Nightly overlay.
        overlays = [
            (import ../overlays/nixpkgs-mozilla/lib-overlay.nix)
            (import ../overlays/nixpkgs-mozilla/firefox-overlay.nix)
        ];
    };

    environment = {
        systemPackages = with pkgs; [

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
            xfsprogs
            zip

            #-- GRAPHICS
            egl-wayland
            imagemagick
            jpegoptim
            jq
            libdrm
            libglvnd
            libva
            libva-utils
            libva1
            mesa
            nvtop
            virtualgl
            wayland-utils
            xdg-desktop-portal
            xdg-utils
            xorg.libxcb
            xorg.xrdb
            xrgears

            #-- KDE/PLASMA
            libsForQt5.full
            libsForQt5.qt5ct

            kdePackages.full
            kdePackages.qt6ct

            kdePackages.accounts-qt
            kdePackages.akonadi
            kdePackages.akonadi-calendar
            kdePackages.akonadi-calendar-tools
            kdePackages.akonadi-contacts
            kdePackages.ark
            kdePackages.dolphin
            kdePackages.dolphin-plugins
            kdePackages.frameworkintegration
            kdePackages.ghostwriter
            kdePackages.kate
            kdePackages.karchive
            kdePackages.kbreakout
            kdePackages.kcalc
            kdePackages.kcmutils
            kdePackages.kcoreaddons
            kdePackages.kdeconnect-kde
            kdePackages.kdeplasma-addons
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
            kdePackages.knewstuff
            kdePackages.ksshaskpass
            kdePackages.ksvg
            kdePackages.ktorrent
            kdePackages.kwallet
            kdePackages.kwallet-pam
            kdePackages.okular
            kdePackages.plasma5support
            kdePackages.plasma-browser-integration
            kdePackages.plasma-wayland-protocols
            kdePackages.plymouth-kcm
            kdePackages.qt5compat
            kdePackages.qtsvg
            kdePackages.qttools
            kdePackages.qtvirtualkeyboard
            kdePackages.wrapQtAppsHook
            kdePackages.xdg-desktop-portal-kde

            python311Packages.gyp
            python311Packages.pyqt6
            python311Packages.pytz

            #-- GNOME/GTK
            gtk3
            gtk4

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

            # php81Packages.php-codesniffer
            php81Packages.php-cs-fixer
            php81Packages.phpmd
            php81Packages.phpstan

            #-- SECURITY
            chkrootkit
            encfs
            lynis
            mkcert
            sniffnet

            #-- EDITORS
            blender
            darktable
            gcolor3
            gegl
            gimp
            inkscape
            # libreoffice-qt
            nomacs
            nano
            onlyoffice-bin_latest
            sublime4-dev
            neovim

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
            (pkgs.callPackage ../custom/anytype/default.nix {})

            #-- GIMP Development
            # (pkgs.callPackage ../custom/gegl-devel/default.nix {})
            # (pkgs.callPackage ../custom/gimp-devel/default.nix {})

            #-- Klassy KDE Theme
            #(pkgs.libsForQt5.callPackage ../custom/klassy/default.nix {})

            #-- Standard Notes
            (pkgs.callPackage ../custom/standardnotes/default.nix {})

            #-- Strawberry Music Player
            (pkgs.callPackage ../custom/strawberry/default.nix {})

            #-- Wavebox Beta
            (pkgs.callPackage ../custom/wavebox/default.nix {})

            #
            # --------------
            #

            (pkgs.writeShellScriptBin "qemu-system-x86_64-uefi" ''
                qemu-system-x86_64 -bios ${pkgs.OVMF.fd}/FV/OVMF.fd "$@"
            '')

        ];

        sessionVariables = {

            ##
            # Desktop
            ####################################################################

            # DESKTOP_SESSION = "plasmax11";
            # XDG_CURRENT_DESKTOP = "KDE";
            # XDG_SESSION_DESKTOP = "KDE" ;
            # XDG_SESSION_TYPE = "x11";

            QT_QPA_PLATFORMTHEME = "qt6ct";

            # # NVIDIA
            # GBM_BACKEND = "nvidia-drm";
            # __GLX_VENDOR_LIBRARY_NAME = "nvidia";
            # LIBVA_DRIVER_NAME = "nvidia";
            # __GL_GSYNC_ALLOWED = "1";

            # WLR_DRM_NO_ATOMIC = "1";
            # WLR_NO_HARDWARE_CURSORS = "1";

            # # JetBrains
            # _JAVA_AWT_WM_NONREPARENTING = "1";

            # SDL_VIDEODRIVER = "wayland";

            MOZ_ENABLE_WAYLAND = "1";
            NIXOS_OZONE_WL = "1";


            GST_PLUGIN_SYSTEM_PATH_1_0=lib.makeSearchPathOutput "lib" "lib/gstreamer-1.0" [
                pkgs.gst_all_1.gst-editing-services
                pkgs.gst_all_1.gst-libav
                pkgs.gst_all_1.gst-plugins-bad
                pkgs.gst_all_1.gst-plugins-base
                pkgs.gst_all_1.gst-plugins-good
                pkgs.gst_all_1.gst-plugins-ugly
                pkgs.gst_all_1.gstreamer
            ];

            XDG_MENU_PREFIX = "kde-";

            XCURSOR_THEME = "ComixCursors";
            DEFAULT_BROWSER = "/run/current-system/sw/bin/firefox-nightly";
        };
    };

}
