{ pkgs, ... }: {

    # Setup.
    nixpkgs = {
        config = {
            allowBroken = true;     # For 'php-packages'
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
                "vulkan-headers"
                "vulkan-loader"
                "vulkan-tool"
                "vulkan-validation-layers"
            ];

            permittedInsecurePackages = [
                "olm-3.2.16"
                "openssl-1.1.1w"
            ];
        };

        overlays =
#        let
#            # Change this to a rev sha to pin
#            moz-rev = "master";
#            moz-url = builtins.fetchTarball {
#                url = "https://github.com/mozilla/nixpkgs-mozilla/archive/${moz-rev}.tar.gz";
#            };
#            nightlyOverlay = (import "${moz-url}/firefox-overlay.nix");
#        in [
#            nightlyOverlay
#        ] ++ [
        [

            # Conky
#            (import ../packages/conky)

            # Firefox Nightly
#            (import ../../overlays/nixpkgs-mozilla/firefox-overlay.nix)
#            (import (builtins.fetchurl {
#               url = "https://raw.githubusercontent.com/mozilla/nixpkgs-mozilla/refs/heads/master/firefox-overlay.nix";
#            }))

            # PhpStorm
            (import ../packages/jetbrains)
        ];
    };

    environment.systemPackages = with pkgs; [
        #--  NIXOS
        nixos-icons
        nixos-rebuild-ng

        #--  BASE
        aha
        babl
        bluez
        clinfo
        coreutils-full
        curl
        dwz
        exfatprogs
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
        linuxquota
        lm_sensors
        lsd
        lshw
        moreutils
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
        python312Full
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

        #--  SECURITY
        certbot
        chkrootkit
        encfs
        lynis
        mkcert
        sniffnet

        #--  GRAPHICS
        cairo
        egl-wayland
        eglexternalplatform
        figma-linux
        glxinfo
        gpm
        imagemagick
        inkscape
        iro
        jpegoptim
        jq
        libGL
        libdrm
        libglvnd
        libva
        libva-utils
        libva1
        mesa
        nvidia-vaapi-driver
        nvtopPackages.full
        virtualgl
        vulkan-headers
        vulkan-loader
        vulkan-tools
        vulkan-validation-layers
        wayland-utils
        wmctrl
        xdg-utils
        xorg.libxcb

        #--  DEVELOPMENT
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
        superhtml
        yarn

        jetbrains.jdk
        nano
        phpstorm    # Custom overlay.
        sublime4

        #--  OFFICE/ADMIN
        libreoffice-qt6-fresh
        nomacs
        notes
        semantik
        standardnotes
        typst

        #--  MULTIMEDIA
        faac
        ffmpeg-full
        ffmpegthumbnailer
        flac
        isoimagewriter
        kodi-wayland
        koreader
        lame
        libcue
        mac
        mkcue
        mpg123
        mpv
        mpvScripts.thumbfast
        opusTools
        pavucontrol
        shntool
        sox
        speechd
        vorbis-tools
        wavpack
        xnviewmp

        #--  NETWORK
        filezilla
        google-chrome
        links2
        megasync
        megatools
        ngrok
        nyxt
        protonvpn-gui

        #--  DESKTOP
        conky
        ly
        ulauncher

        #--  THEME
        comixcursors

        #--  MISCELLANEOUS
        diskscan
        ghostty
        libportal
        mozlz4a
        pandoc
#        p7zip
        p7zip-rar
#        peazip
        systemctl-tui
        trilium-next-desktop
        wezterm


        #--  CUSTOM PACKAGES

        #--  Capacities
#        (pkgs.callPackage ../packages/capacities {})

        # LadyBird
        (pkgs.callPackage ../packages/ladybird {})

        # Strawberry Music Player
        (pkgs.callPackage ../packages/strawberry {})

        # Vivaldi Browser
        (pkgs.callPackage ../packages/vivaldi {})

        # Wavebox Beta
        (pkgs.callPackage ../packages/wavebox {})
    ];

    imports = [
        ../packages/gimp
        ../packages/gnome-desktop
        ../packages/kde-desktop
        ../packages/ngrok
        ../packages/php
        ../packages/vaapi
    ];

}
