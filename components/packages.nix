{ config, pkgs, lib, ... }:

let
    # --- Custom Package Definitions ---
    customPkgs = {
        gemini-wrapped = pkgs.callPackage ../custom-packages/gemini-cli/wrapper.nix {};
        gemini-nix     = pkgs.callPackage ../custom-packages/gemini-nix-assistant/default.nix {};
        gh-clone       = pkgs.callPackage ../custom-packages/gh-clone/default.nix {};
        gemini-desktop = pkgs.callPackage ../custom-packages/gemini-desktop/default.nix {};
        nyxt-custom    = pkgs.callPackage ../custom-packages/nyxt-custom/default.nix { };
        strawberry     = pkgs.callPackage ../custom-packages/strawberry-master {};
        vivaldi        = pkgs.callPackage ../custom-packages/vivaldi-snapshot {};
        wavebox        = pkgs.callPackage ../custom-packages/wavebox-beta {};
    };

    # --- Package Categories ---
    pkgsByCategories = {
        nixos = with pkgs; [
            nixos-icons
            nixos-rebuild-ng
        ];

        development = with pkgs; [
            cargo
            cppcheck
            cmake
            ddev
            extra-cmake-modules
            gcc
            gdb
            git
            gnumake
            ninja
            nodejs
            phpstorm
            phpunit
            pkg-config
            pre-commit
            rustc
            sublime4
            yarn
        ];

        system-tools = with pkgs; [
            coreutils-full
            curl
            diffutils
            dysk
            fwupd
            fwupd-efi
            htop
            inetutils
            inxi
            killall
            lsd
            lshw
            nvme-cli
            pciutils
            smartmontools
            systemctl-tui
            usbutils
            wget
        ];

        graphics-multimedia = with pkgs; [
            cairo
            ffmpeg-full
            ffmpegthumbnailer
            figma-linux
            imagemagick
            inkscape
            mpv-unwrapped
            mpvScripts.autosub
            mpvScripts.sponsorblock
            mpvScripts.uosc
            nomacs
            nvtopPackages.full
            pavucontrol
            vulkan-tools
            xnviewmp
        ];

        network-web = with pkgs; [
            filezilla
            firefox-nightly
            google-chrome
            links2
            megasync
            megatools
            microsoft-edge
            mullvad-browser
#            nyxt
            openvpn
            protonvpn-gui
            tor-browser
        ];

        security = with pkgs; [
            certbot
            clamav
            encfs
            lynis
            mkcert
            sniffnet
        ];

        utilities = with pkgs; [
            comixcursors
            conky
            jq
            libnotify
            ly
            p7zip-rar
            rofi
            tldr
            unrar
            unzip
            wezterm
            xclip
            zip
        ];

        custom = builtins.attrValues customPkgs;
    };

in {
    imports = [
        ../custom-packages/firefox-stable
        ../custom-packages/gimp
        ../custom-packages/gnome-desktop
        ../custom-packages/kde-desktop
        ../custom-packages/php
        ../custom-packages/vaapi
    ];

    # Flatten the attribute set of lists into a single list.
    environment.systemPackages = lib.flatten (builtins.attrValues pkgsByCategories);

    # Ensure specialized drivers are prioritized.
    hardware.graphics = {
        enable = true;
        extraPackages = with pkgs; [
            nvidia-vaapi-driver
            libva-vdpau-driver
            libvdpau-va-gl
        ];
    };
}

# <> #
