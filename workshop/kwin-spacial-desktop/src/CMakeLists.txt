#######################################
# Effect plugin

set(spacialdesktop_SOURCES
    main.cpp
    spacialdesktop.cpp
)

kconfig_add_kcfg_files(spacialdesktop_SOURCES
    spacialdesktopconfig.kcfgc
)

kcoreaddons_add_plugin(spacialdesktop
    INSTALL_NAMESPACE "kwin/effects/plugins"
    SOURCES ${spacialdesktop_SOURCES}
)

target_link_libraries(spacialdesktop PRIVATE
    KWin::kwin
    KF6::ConfigGui
    KF6::CoreAddons
)

#######################################
# Config KCM

set(kwin_spacialdesktop_config_SOURCES
    kcm/spacialdesktop_config.cpp
)

ki18n_wrap_ui(kwin_spacialdesktop_config_SOURCES
    kcm/spacialdesktop_config.ui
)

kconfig_add_kcfg_files(kwin_spacialdesktop_config_SOURCES
    spacialdesktopconfig.kcfgc
)

kcoreaddons_add_plugin(kwin_spacialdesktop_config
    INSTALL_NAMESPACE "kwin/effects/configs"
    SOURCES ${kwin_spacialdesktop_config_SOURCES}
)

target_link_libraries(kwin_spacialdesktop_config PRIVATE
    KF6::KCMUtils
    KF6::CoreAddons
    KF6::I18n
    KF6::WidgetsAddons
    Qt::DBus
    Qt::Widgets
)
