{ pkgs, ... }: {
    environment.systemPackages = (with pkgs; [

        # Klassy KDE Theme
        (pkgs.callPackage ./kde-klassy.nix {})

        materia-kde-theme

    ]) ++ (with pkgs.kdePackages; [

        #-- KDE
        full
        qt6ct
        accounts-qt
        akonadi
        akonadi-calendar
        akonadi-calendar-tools
        akonadi-contacts
        akonadi-import-wizard
        akonadi-mime
        akonadi-notes
        akonadi-search
        ark
        baloo
        baloo-widgets
        dolphin
        dolphin-plugins
        ffmpegthumbs
        frameworkintegration
        kajongg
        kate
        karchive
        kcalc
        kcmutils
        kcolorpicker
        kconfigwidgets
        kcoreaddons
        kde-cli-tools
        kdeconnect-kde
        kdecoration
        kdegraphics-thumbnailers
        kdeplasma-addons
        kdesdk-thumbnailers
        kglobalaccel
        kglobalacceld
        kguiaddons
        kiconthemes
        kio
        kio-admin
        kio-extras
        kio-extras-kf5
        kio-fuse
        kio-gdrive
        kio-zeroconf
        ksshaskpass
        ksvg
        ktorrent
        kwallet
        kwallet-pam
        kwayland
        kwindowsystem
        layer-shell-qt
        modemmanager-qt
        networkmanager-qt
        okular
        partitionmanager
        plasma-browser-integration
        plasma-desktop
        plasma-disks
        plasma-integration
        plasma-wayland-protocols
        plasma-workspace
        #plymouth-kcm
        qtsvg
        qttools
        taglib
        wayland
        wayland-protocols
        wayqt
        wrapQtAppsHook
        xdg-desktop-portal-kde

        breeze
        breeze-icons
        qtstyleplugin-kvantum
        sierra-breeze-enhanced

    ]);
}
