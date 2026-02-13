cmake_minimum_required(VERSION 3.16)

project(claude-ai VERSION 1.0.0)

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
    GlobalAccel
    Notifications
    StatusNotifierItem
)

add_executable(claude-ai main.cpp)

target_link_libraries(claude-ai
    Qt6::WebEngineWidgets
    Qt6::Widgets
    KF6::GlobalAccel
    KF6::Notifications
    KF6::StatusNotifierItem
)

install(TARGETS claude-ai ${KDE_INSTALL_TARGETS_DEFAULT_ARGS})
install(FILES claude-ai.notifyrc DESTINATION ${KDE_INSTALL_KNOTIFYRCDIR})
