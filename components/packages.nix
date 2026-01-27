{ pkgs, ... }: {
    environment.systemPackages = with pkgs; [
        #--  NIXOS
        nixos-icons
        nixos-rebuild-ng

        #--  BASE
        aha
        alac
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
        dsf2flac
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
        ttaenc
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
        codex   # Lightweight coding agent
        ddev
        docker-compose
        git
        yarn


        nano
        phpstorm    # From custom overlay.
        sublime4

        #--  OFFICE/ADMIN
        libreoffice-qt6-fresh
        nomacs
        notes
        standardnotes

        #--  MULTIMEDIA
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
        microsoft-edge
        mullvad-browser
        nyxt
        protonvpn-gui
        tor-browser

        #--  UTILITIES
        comixcursors
        conky
        dysk
        inxi
        moltbot    # From custom overlay.
        neohtop
        ly
#        p7zip
        p7zip-rar
#        peazip
        rofi
        systemctl-tui
        wezterm


        #--  CUSTOM PACKAGES

        # Strawberry Music Player
        (pkgs.callPackage ../packages/strawberry-master {})

        # Vivaldi Browser
        (pkgs.callPackage ../packages/vivaldi-snapshot {})

        # Wavebox Beta
        (pkgs.callPackage ../packages/wavebox-beta {})
    ];

    imports = [
        ../packages/firefox-nightly
        ../packages/firefox-stable
        ../packages/gimp
        ../packages/gnome-desktop
        ../packages/kde-desktop
        ../packages/php
        ../packages/vaapi
    ];
}

# <> #
