{ pkgs, ... }: {
    environment.systemPackages = with pkgs; [
        #--  NIXOS
        nixos-icons
        nixos-rebuild-ng

        #--  BASE
        aha
        babl
        bison
        bisoncpp
        bluez
        cairo
        cargo
        clinfo
        cmake
        coreutils-full
        curl
        desktop-file-utils
        diffutils
        dwz
        egl-wayland
        eglexternalplatform
        eww
        exfatprogs
        expat
        expect
        extra-cmake-modules
        faac
        ffmpeg-full
        ffmpegthumbnailer
        flac
        flex
        fontconfig
        fwupd
        fwupd-efi
        gcc
        gcr
        gd
        gdb
        glxinfo
        gpm
        gsasl
        imagemagick
        inetutils
        inotify-tools
        iro
        jpegoptim
        jq
        killall
        lame
        libGL
        libcue
        libdrm
        libglvnd
        libportal
        libunwind
        libva
        libva-utils
        libva1
        libxfs
        libxml2
        linuxquota
        lm_sensors
        lsd
        lshw
        lua
        mac
        mesa
        mkcue
        moreutils
        mozlz4a
        mpg123
        mpvScripts.thumbfast
        nix-du
        nix-index
        nix-prefetch-git
        nodejs
        nvidia-vaapi-driver
        nvme-cli
        nvtopPackages.full
        openssl
        openvpn
        optipng
        opusTools
        pandoc
        pavucontrol
        pciutils
        pcre2
        perl
        phpunit
        pmutils
        pngquant
        pre-commit
        rar
        rustc

        shntool
        smartmontools
        sox
        speechd
        superhtml
        tldr
        unar
        unixtools.script
        unrar
        unzip
        usbutils
        virtualgl
        vorbis-tools
        vulkan-headers
        vulkan-loader
        vulkan-tools
        vulkan-validation-layers
        wavpack
        wayland-utils
        wget
        wirelesstools
        wmctrl
        xclip
        xdg-utils
        xfsprogs
        xnviewmp
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

        #--  DEVELOPMENT
        ddev
        docker
        docker-buildx
        docker-client
        docker-compose
        git
        yarn

        nano
        phpstorm    # Custom overlay.
        sublime4

        #--  OFFICE/ADMIN
        libreoffice-qt6-fresh
        nomacs
        notes
        standardnotes

        #--  MULTIMEDIA
        isoimagewriter
        mpv-unwrapped
        mpvScripts.autosub
        mpvScripts.sponsorblock
        mpvScripts.uosc

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
#        diskscan
        inxi
        neohtop
#        p7zip
        p7zip-rar
#        peazip
        systemctl-tui
        warzone2100
        wezterm
#        xorg.xdpyinfo
#        xorg.xeyes

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
