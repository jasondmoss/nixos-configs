cmake_minimum_required(VERSION 3.20)
project(proton-suite)

# Standard C++23 setup
set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

find_package(ECM REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH})

include(KDEInstallDirs)

find_package(Qt6 6.8 REQUIRED COMPONENTS
    Core
    Gui
    Qml
    Quick
    WebEngineQuick
)
find_package(KF6 6.5 REQUIRED COMPONENTS
    CoreAddons
    DBusAddons
    GlobalAccel
    I18n
    Notifications
    StatusNotifierItem
    WindowSystem
)

add_executable(proton-suite
    src/main.cpp
    src/controller.cpp
    # src/controller.h
)

target_link_libraries(proton-suite PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::WebEngineQuick
    KF6::CoreAddons
    KF6::DBusAddons
    KF6::GlobalAccel
    KF6::I18n
    KF6::Notifications
    KF6::StatusNotifierItem
    KF6::WindowSystem
)

install(FILES src/assets/proton-suite.svg
    DESTINATION ${KDE_INSTALL_ICONDIR}/hicolor/scalable/apps)

install(TARGETS proton-suite DESTINATION ${KDE_INSTALL_BINDIR})

# Embed QML resources
qt_add_qml_module(proton-suite
    URI "ProtonSuite"
    VERSION 1.0
    QML_FILES
        src/qml/Main.qml
        src/qml/ProtonTab.qml
)

install(FILES src/assets/proton-suite.svg
    DESTINATION ${KDE_INSTALL_ICONDIR}/hicolor/scalable/apps)

install(TARGETS proton-suite DESTINATION bin)
