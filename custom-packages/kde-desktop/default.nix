{ pkgs, ... }: {
    environment = {
        plasma6.excludePackages = (with pkgs.kdePackages; [
            elisa
            itinerary
        ]);

        systemPackages = (with pkgs; [
            # Darkly KDE theme engine
            (pkgs.callPackage ../kde-darkly {})
            # Klassy KDE theme engine
            (pkgs.callPackage ../kde-klassy {})

            clazy
            gammaray
            heaptrack
            qtcreator
            valgrind

            # Theming
            adwaita-qt6
            materia-kde-theme
            qadwaitadecorations-qt6
        ]) ++ (with pkgs.kdePackages; [
            qt6ct
            accounts-qt
            ark
            baloo
            baloo-widgets
            bluedevil
            dolphin
            dolphin-plugins
            drkonqi
            ffmpegthumbs
            frameworkintegration
            ghostwriter
            isoimagewriter
#            itinerary
            kate
            karchive
            kbreakout
            kcachegrind
            kcalc
            kcmutils
            kconfigwidgets
            kcoreaddons
            kde-cli-tools
            kdeconnect-kde
            kdecoration
            kdegraphics-thumbnailers
            kdenlive
            kdeplasma-addons
            kdesdk-thumbnailers
            kdevelop
            kglobalaccel
            kglobalacceld
            kguiaddons
            khelpcenter
            kiconthemes
            kimageformats
            kio
            kio-admin
            kio-extras
            kio-extras-kf5
            kio-fuse
            kio-gdrive
            kio-zeroconf
            kitinerary
            koko
            kompare
            krdc
            krdp
            ksshaskpass
            ksvg
            ktorrent
            ktrip
            kwallet
            kwallet-pam
            kwayland
            kwindowsystem
            layer-shell-qt
            modemmanager-qt
            networkmanager-qt
            okular
            partitionmanager
            plasma5support
            plasma-browser-integration
            plasma-desktop
            plasma-disks
            plasma-integration
            plasma-wayland-protocols
            plasma-workspace
            qtbase
            qtdeclarative
            qtsvg
            qttools
            taglib
            wayland
            wayland-protocols
            wrapQtAppsHook

            akonadi
            akonadi-calendar
            akonadi-calendar-tools
            akonadi-contacts
            akonadi-import-wizard
            akonadi-mime
            akonadi-search
            calendarsupport

            breeze
            breeze-icons
            qtstyleplugin-kvantum
        ]);
    };
}
