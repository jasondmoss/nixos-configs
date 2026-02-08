cmake_minimum_required(VERSION 3.16)

project(feedbin-rss VERSION 1.0.0)

find_package(ECM 6.20 REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH})

include(KDEInstallDirs)
include(KDECMakeSettings)
include(KDECompilerSettings NO_POLICY_SCOPE)

find_package(Qt6 6.10 REQUIRED COMPONENTS
    WebEngineWidgets
    Widgets
)
find_package(KF6 6.20 REQUIRED COMPONENTS
    StatusNotifierItem
    GlobalAccel
    KIO
    JobWidgets
)

add_executable(feedbin-rss main.cpp)

target_link_libraries(feedbin-rss
    Qt6::WebEngineWidgets
    Qt6::Widgets
    Qt6::Gui
    KF6::StatusNotifierItem
    KF6::GlobalAccel
    KF6::KIOWidgets
    KF6::JobWidgets
)

install(TARGETS feedbin-rss ${KDE_INSTALL_TARGETS_DEFAULT_ARGS})
