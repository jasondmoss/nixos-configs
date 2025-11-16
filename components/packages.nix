{ pkgs, ... }: {
    environment.systemPackages = with pkgs; [
        #--  NIXOS
        nixos-icons
        nixos-rebuild-ng

        #--  BASE
        aha
        audit
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
        fop
        fwupd
        fwupd-efi
        gcc
        gcr
        gd
        gdb
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
        libgcrypt
        libglvnd
        libportal
        libselinux
        libunwind
        libva
        libva-utils
        libva1
        libxfs
        libxml2
        libxslt
        linuxquota
        lm_sensors
        lsd
        lshw
        lua
        mesa
        mesa-demos
        mkcue
        monkeysAudio
        moreutils
        mozlz4a
        mpg123
        mpvScripts.thumbfast
        nettle
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
        xmlto
        xnviewmp
        xorg.libxcb
        xorg.xorgsgmldoctools
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
#        protonvpn-gui
#        vivaldi
        zoom-us

        #--  DESKTOP
        conky
        ly

        #--  THEME
        comixcursors

        #--  MISCELLANEOUS
        inxi
        neohtop
#        p7zip
        p7zip-rar
#        peazip
        systemctl-tui
        wezterm


        #--  CUSTOM PACKAGES

        # Strawberry Music Player
        (pkgs.callPackage ../packages/strawberry {})

        # Vivaldi Browser
        (pkgs.callPackage ../packages/vivaldi-snapshot {})

        # Wavebox Beta
        (pkgs.callPackage ../packages/wavebox {})
    ];

    imports = [
#        ../packages/conky
        ../packages/firefox-nightly
        ../packages/firefox-stable
        ../packages/gimp
        ../packages/gnome-desktop
        ../packages/kde-desktop
#        ../packages/ngrok
        ../packages/php
#        ../packages/protonpass
#        ../packages/python
        ../packages/vaapi
    ];
}

# <> #
