{ config, lib, pkgs, ... }:
let

  # Firefox Nightly
  firefoxNightlyDesktopItem = pkgs.makeDesktopItem rec {
    type = "Application";
    terminal = false;
    name = "FirefoxNightly";
    desktopName = "FirefoxNightly";
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

  # Firefox Stable
  firefoxStableDesktopItem = pkgs.makeDesktopItem rec {
    type = "Application";
    terminal = false;
    name = "FirefoxStable";
    desktopName = "FirefoxStable";
    exec = "firefox-stable -P \"Default\" %u";
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

      permittedInsecurePackages = [ "openssl-1.1.1v" ];
    };

    overlays = [
      (import ./overlays/nixpkgs-mozilla/lib-overlay.nix)
      (import ./overlays/nixpkgs-mozilla/firefox-overlay.nix)
    ];
  };


  environment = {
    systemPackages = with pkgs; [

      #-- Core
      babl
      coreutils-full
      curl
      expect
      ffmpeg
      ffmpegthumbnailer
      flex
      fwupd
      fwupd-efi
      gcr
      gd
      gsasl
      imagemagick
      inetutils
      inotify-tools
      jpegoptim
      jq
      killall
      libxml2
      links2
      lm_sensors
      nix-du
      nix-index
      nix-prefetch-git
      nixFlakes
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

      nvidia-vaapi-driver
      egl-wayland


      #-- Core Utils
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


      #-- GNOME/GTK
      gtk3 gtk3-x11
      gtk4
      xdg-desktop-portal
      xdg-desktop-portal-gnome
      xdg-desktop-portal-gtk
      xdg-utils
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

#      qt6.qtgrpc # Currently not compatible with latest protobuf
#      qt6.full # Build fails with qt6.qtgrpc
      qt6.qt5compat
      qt6.qtbase
      qt6.qtimageformats
      qt6.qtmultimedia
      qt6.qttools
      qt6.qtwayland
      qt6.qtwebengine
      qt6.qtwebview
      qt6.wrapQtAppsHook

      qt6Packages.qt6ct
      qt6Packages.qt6gtk2
      qt6Packages.qtstyleplugin-kvantum
      qt6Packages.quazip

      python310Packages.pyqt6
      python311Packages.pyqt6

      ksmoothdock


      #-- Theming
      adwaita-qt6
      adapta-kde-theme
      adementary-theme
      arc-kde-theme
      ayu-theme-gtk

      gnome.adwaita-icon-theme
      gnome-icon-theme
      pantheon.elementary-icon-theme


      #-- Development
      bison
      bisoncpp
      bun
      cargo
      cmake
      desktop-file-utils
      eww
      gcc
      git
      go
      lua
      nodejs
      perl
      rustc
      yarn

      php82
      php82Extensions.bz2
      php82Extensions.curl
      php82Extensions.gd
      php82Extensions.intl
      php82Extensions.mbstring
      php82Extensions.mysqlnd
      php82Extensions.pdo
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


      #-- Security
      chkrootkit
      encfs
      lynis
      sniffnet
      wireshark


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


      #-- Multimedia
      libdrm
      libva
      libva-minimal
      libva-utils
      libva1
      libva1-minimal
      mpg321
      speechd
      vaapiVdpau

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
      flatpak
      flatpak-builder
      libportal
      protonmail-bridge
      protonvpn-cli
      protonvpn-gui
      sticky
      ulauncher
      wezterm

    ] ++ [

      #
      #  Custom Package Builds.
      #

      #-- Firefox Nightly (nixpkgs-mozilla) -- Rename executable
      (pkgs.runCommand "firefox-nightly" {
        preferLocalBuild = true;
      } ''
        mkdir -p $out/bin
        ln -s ${latest.firefox-nightly-bin}/bin/firefox $out/bin/firefox-nightly
      '')
      # Create desktop file
      firefoxNightlyDesktopItem

      #-- Firefox Stable -- Rename executable
      (pkgs.runCommand "firefox-stable" {
        preferLocalBuild = true;
      } ''
        mkdir -p $out/bin
        ln -s ${pkgs.firefox}/bin/firefox $out/bin/firefox-stable
      '')
      # Create desktop file
      firefoxStableDesktopItem

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
#      (pkgs.libsForQt5.callPackage ./pkgs/masterpdf5/default.nix {})

      #-- QT 6: GRPC - Needs work
#      (pkgs.qt6.callPackage ./pkgs/qtgrpc/default.nix {})

      #-- QT 6 - Needs work
#      (pkgs.qt6Packages.callPackage ./pkgs/qt-6/default.nix {})

      #-- Standard Notes
      (pkgs.callPackage ./pkgs/standardnotes/default.nix {})

      #-- Strawberry Music Player
      (pkgs.callPackage ./pkgs/strawberry/default.nix {})

      #-- Wavebox Beta
      (pkgs.callPackage ./pkgs/wavebox/default.nix {})

    ];

    sessionVariables = {
      DEFAULT_BROWSER = "${pkgs.latest.firefox-nightly-bin}/bin/firefox-nightly -P 'Nightly'";
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
