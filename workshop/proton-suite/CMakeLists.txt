cmake_minimum_required(VERSION 3.16)

project(proton-suite VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(ECM 6.0.0 REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH})

include(KDEInstallDirs)
include(KDECMakeSettings)
include(KDECompilerSettings NO_POLICY_SCOPE)

find_package(Qt6 REQUIRED COMPONENTS Quick WebEngineQuick Core Gui Widgets WebChannel)
find_package(KF6Kirigami REQUIRED)
find_package(KF6StatusNotifierItem REQUIRED)

qt_standard_project_setup()

qt_add_executable(proton-suite
    ${CMAKE_CURRENT_SOURCE_DIR}/src/main.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/src/resources.qrc
)

target_link_libraries(proton-suite
    PRIVATE
    Qt6::Quick
    Qt6::WebEngineQuick
    Qt6::Widgets
    Qt6::WebChannel
    KF6::Kirigami
    KF6::StatusNotifierItem
)

install(TARGETS proton-suite
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${KDE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${KDE_INSTALL_BINDIR}
)

# [FIX] Install SVG to the 'scalable' directory.
# If this path is wrong, the icon will not appear in the menu.
install(FILES src/assets/proton-suite.svg
    DESTINATION ${KDE_INSTALL_ICONDIR}/hicolor/scalable/apps
)
