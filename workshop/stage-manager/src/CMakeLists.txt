#######################################
# Effect plugin

set(stagemanager_SOURCES
    main.cpp
    stagemanager.cpp
)

kconfig_add_kcfg_files(stagemanager_SOURCES
    stagemanagerconfig.kcfgc
)

kcoreaddons_add_plugin(stagemanager
    INSTALL_NAMESPACE "kwin/effects/plugins"
    SOURCES ${stagemanager_SOURCES}
)

target_link_libraries(stagemanager PRIVATE
    KWin::kwin
    KF6::ConfigGui
    KF6::CoreAddons
    Qt::DBus
)

#######################################
# Config KCM

set(kwin_stagemanager_config_SOURCES
    kcm/stagemanager_config.cpp
)

ki18n_wrap_ui(kwin_stagemanager_config_SOURCES
    kcm/stagemanager_config.ui
)

kconfig_add_kcfg_files(kwin_stagemanager_config_SOURCES
    stagemanagerconfig.kcfgc
)

kcoreaddons_add_plugin(kwin_stagemanager_config
    INSTALL_NAMESPACE "kwin/effects/configs"
    SOURCES ${kwin_stagemanager_config_SOURCES}
)

target_link_libraries(kwin_stagemanager_config PRIVATE
    KF6::KCMUtils
    KF6::CoreAddons
    KF6::I18n
    KF6::WidgetsAddons
    Qt::DBus
    Qt::Widgets
)
