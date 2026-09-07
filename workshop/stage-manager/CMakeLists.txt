cmake_minimum_required(VERSION 3.25)
project(stage-manager VERSION 0.1.0)

set(QT_MIN_VERSION "6.10.0")
set(KF6_MIN_VERSION "6.26.0")

find_package(ECM ${KF6_MIN_VERSION} REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH})

include(KDEInstallDirs)
include(KDECMakeSettings)
include(KDECompilerSettings NO_POLICY_SCOPE)
include(FeatureSummary)

find_package(Qt6 ${QT_MIN_VERSION} REQUIRED COMPONENTS Core Gui Widgets DBus)
find_package(KF6 ${KF6_MIN_VERSION} REQUIRED COMPONENTS
    Config
    CoreAddons
    KCMUtils
    I18n
    WindowSystem
    GuiAddons
    WidgetsAddons
)
find_package(KWin REQUIRED)

add_subdirectory(src)

feature_summary(WHAT ALL FATAL_ON_MISSING_REQUIRED_PACKAGES)
