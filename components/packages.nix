{ pkgs, ... }: {
    environment.systemPackages = with pkgs; [
        #--  NIXOS
        nixos-icons
        nixos-rebuild-ng

        #--  BASE
        aha
        babl
        bluez
        cairo
        clinfo
        coreutils-full
        curl
        dwz
        egl-wayland
        eglexternalplatform
        exfatprogs
        expat
        expect
        flex
        fontconfig
        fwupd
        fwupd-efi
        gcr
        gd
        glxinfo
        gpm
        gsasl
        imagemagick
        inetutils
        inotify-tools
        iro
        killall
        libdrm
        libGL
        libglvnd
        libva
        libva-utils
        libva1
        libxfs
        libxml2
        linuxquota
        lm_sensors
        lsd
        lshw
        mesa
        moreutils
        nix-du
        nix-index
        nix-prefetch-git
        nvidia-vaapi-driver
        nvme-cli
        nvtopPackages.full
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
        virtualgl
        vulkan-headers
        vulkan-loader
        vulkan-tools
        vulkan-validation-layers
        wayland-utils
        wget
        wirelesstools
        wmctrl
        xclip
        xdg-utils
        xfsprogs
        xorg.libxcb
        zip

        #--  SECURITY
        certbot
        clamav
        encfs
        lynis
        mkcert
        sniffnet

        #--  GRAPHICS
        figma-linux
        inkscape
        jpegoptim
        jq

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

        #--  THEME
        comixcursors

        #--  MISCELLANEOUS
        diskscan
        inxi
        librechat
        libportal
        mozlz4a
        nheko
        neohtop
        pandoc
#        p7zip
        p7zip-rar
#        peazip
        systemctl-tui
        warzone2100
        wezterm
        xorg.xdpyinfo
        xorg.xeyes

        #--  CUSTOM PACKAGES

        # Strawberry Music Player
        (pkgs.callPackage ../packages/strawberry {})

        # Vivaldi Browser
        (pkgs.callPackage ../packages/vivaldi {})

        # Wavebox Beta
        (pkgs.callPackage ../packages/wavebox {})
    ];

    imports = [
        ../packages/firefox-nightly
        ../packages/firefox-stable
        ../packages/gimp
        ../packages/gnome-desktop
        ../packages/kde-desktop
#        ../packages/ngrok
        ../packages/php
        ../packages/python
        ../packages/vaapi
    ];
}

# <> #
