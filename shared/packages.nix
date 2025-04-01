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

        overlays = [
            (import ../packages/jetbrains)
            (import (builtins.fetchurl {
                url = "https://raw.githubusercontent.com/mozilla/nixpkgs-mozilla/refs/heads/master/firefox-overlay.nix";
            }))
        ];
    };

    #--  Core Packages.
    environment.systemPackages = with pkgs; [
        #--  BASE
        aha
        babl
        bluez
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

        #--  GRAPHICS
        egl-wayland
        eglexternalplatform
        glxinfo
        gpm
        imagemagick
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
        xdg-desktop-portal
        xdg-utils
        xorg.libxcb

        #--  DESKTOP
        ly

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
        jetbrains.gateway
        jetbrains.jdk
        jetbrains.writerside
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

        #--  SECURITY
        certbot
        chkrootkit
        encfs
        lynis
        mkcert
        sniffnet

        #--  EDITORS
        inkscape
        libreoffice-qt6-fresh
        nano
        nomacs
        notes
        phpstorm    # Custom overlay.
        semantik
        sublime4

        #--  MULTIMEDIA
        #aaxtomp3
        faac
        ffmpeg-full
        ffmpegthumbnailer
        flac
        isoimagewriter
        kodi-wayland
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

        #--  NETWORK
        filezilla
        librewolf
        megasync
        megatools
        microsoft-edge
        ngrok
        nyxt
        opera
        protonvpn-gui

        #--  THEME
        comixcursors

        #--  MISCELLANEOUS
        aichat
        conky
        diskscan
        ghostty
        libportal
        ulauncher
        wezterm

        (google-chrome.override {
            commandLineArgs = [
                "--use-gl=desktop"
                "--enable-features=VaapiVideoDecodeLinuxGL"
                "--ignore-gpu-blocklist"
                "--enable-zero-copy"
            ];
        })

        (chromium.override {
            enableWideVine = true;

            commandLineArgs = [
                "--use-gl=desktop"
                "--enable-features=VaapiVideoDecodeLinuxGL"
                "--ignore-gpu-blocklist"
                "--enable-zero-copy"
            ];
        })


        #--  CUSTOM PACKAGES

        #--  Anytype
        (pkgs.callPackage ../packages/anytype {})

        # Strawberry Music Player
        (pkgs.callPackage ../packages/strawberry {})

        # Wavebox Beta
        (pkgs.callPackage ../packages/wavebox {})
    ];

    imports = [
        ../packages/php
        #../packages/ngrok
        ../packages/gnome-desktop
        ../packages/kde-desktop
        ../packages/gimp
        ../packages/firefox-nightly
        ../packages/firefox-stable
        ../packages/floorp
        ../packages/thunderbird
        ../packages/vaapi
    ];

}
