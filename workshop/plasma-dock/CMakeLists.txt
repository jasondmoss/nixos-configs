cmake_minimum_required(VERSION 3.25)
project(plasma-dock VERSION 0.1.0 LANGUAGES C CXX)

# ── Standards ─────────────────────────────────────────────────────────────────
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

# ── Qt / KDE package discovery ────────────────────────────────────────────────
find_package(ECM REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH})

include(KDEInstallDirs)
include(KDECompilerSettings NO_POLICY_SCOPE)
include(KDECMakeSettings)

find_package(Qt6 REQUIRED COMPONENTS
    Core
    Gui
    GuiPrivate          # provides Qt6::GuiPrivate — qpa/qplatformnativeinterface.h
    Quick
    QuickControls2
    DBus
    WaylandClient
    WaylandClientPrivate
)

find_package(KF6 REQUIRED COMPONENTS
    WindowSystem
    Service
    Config
)

find_package(LayerShellQt REQUIRED)

find_package(Wayland REQUIRED COMPONENTS Client)

# ── Wayland protocol code generation ──────────────────────────────────────────
# WaylandScanner_EXECUTABLE is set by ECM's FindWayland.cmake, confirmed working.
# We call wayland-scanner directly — no ECM module wrapper required.

set(PROTOCOL_XML    "${CMAKE_CURRENT_SOURCE_DIR}/protocols/wlr-layer-shell-unstable-v1.xml")
set(PROTOCOL_HEADER "${CMAKE_BINARY_DIR}/protocols/wlr-layer-shell-unstable-v1-client-protocol.h")
set(PROTOCOL_SOURCE "${CMAKE_BINARY_DIR}/protocols/wlr-layer-shell-unstable-v1-protocol.c")

file(MAKE_DIRECTORY "${CMAKE_BINARY_DIR}/protocols")

add_custom_command(
    OUTPUT  "${PROTOCOL_HEADER}"
    COMMAND "${WaylandScanner_EXECUTABLE}" client-header "${PROTOCOL_XML}" "${PROTOCOL_HEADER}"
    DEPENDS "${PROTOCOL_XML}"
    COMMENT "wayland-scanner: client header"
    VERBATIM
)

add_custom_command(
    OUTPUT  "${PROTOCOL_SOURCE}"
    COMMAND "${WaylandScanner_EXECUTABLE}" private-code "${PROTOCOL_XML}" "${PROTOCOL_SOURCE}"
    DEPENDS "${PROTOCOL_XML}"
    COMMENT "wayland-scanner: protocol glue"
    VERBATIM
)

# Tell CMake these files are generated — suppresses "source not found at configure time" errors.
set_source_files_properties(
    "${PROTOCOL_HEADER}"
    "${PROTOCOL_SOURCE}"
    PROPERTIES GENERATED TRUE
)

# ── Executable target ─────────────────────────────────────────────────────────
# Absolute paths — unambiguous regardless of where cmake is invoked from.
add_executable(plasma-dock
    "${CMAKE_CURRENT_SOURCE_DIR}/src/main.cpp"
    "${CMAKE_CURRENT_SOURCE_DIR}/src/iconprovider.h"
    "${CMAKE_CURRENT_SOURCE_DIR}/src/layershellwindow.h"
    "${CMAKE_CURRENT_SOURCE_DIR}/src/layershellwindow.cpp"
    "${CMAKE_CURRENT_SOURCE_DIR}/src/appmodel.h"
    "${CMAKE_CURRENT_SOURCE_DIR}/src/appmodel.cpp"
    "${CMAKE_CURRENT_SOURCE_DIR}/src/windowtracker.h"
    "${CMAKE_CURRENT_SOURCE_DIR}/src/windowtracker.cpp"
    "${CMAKE_CURRENT_SOURCE_DIR}/src/dodgemanager.h"
    "${CMAKE_CURRENT_SOURCE_DIR}/src/dodgemanager.cpp"
    "${CMAKE_CURRENT_SOURCE_DIR}/src/dockadaptor.h"
    "${CMAKE_CURRENT_SOURCE_DIR}/src/dockadaptor.cpp"
    "${PROTOCOL_HEADER}"
    "${PROTOCOL_SOURCE}"
)

# ── QML resources ─────────────────────────────────────────────────────────────
# Target-based form: first arg is the existing target name, second is a
# resource collection identifier (arbitrary string, not a variable).
# Must come AFTER add_executable.
qt6_add_resources(plasma-dock "qml_resources"
    PREFIX "/qml"
    BASE   "${CMAKE_CURRENT_SOURCE_DIR}/qml"
    FILES
        "${CMAKE_CURRENT_SOURCE_DIR}/qml/main.qml"
        "${CMAKE_CURRENT_SOURCE_DIR}/qml/DockIconPlaceholder.qml"
        "${CMAKE_CURRENT_SOURCE_DIR}/qml/DockIcon.qml"
)

# ── Include paths ─────────────────────────────────────────────────────────────
# Private headers come in via Qt6::GuiPrivate and Qt6::WaylandClientPrivate link targets.
target_include_directories(plasma-dock PRIVATE
    "${CMAKE_CURRENT_SOURCE_DIR}/src"
    "${CMAKE_BINARY_DIR}/protocols"
)

# ── Link libraries ────────────────────────────────────────────────────────────
target_link_libraries(plasma-dock PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::GuiPrivate             # adds qpa/ private includes — no extra .so
    Qt6::Quick
    Qt6::DBus
    Qt6::QuickControls2
    Qt6::WaylandClient
    Qt6::WaylandClientPrivate   # adds QtWaylandClient private includes
    KF6::WindowSystem
    KF6::Service
    KF6::ConfigCore
    Wayland::Client
    LayerShellQt::Interface
)

# ── Install ───────────────────────────────────────────────────────────────────
install(TARGETS plasma-dock DESTINATION ${KDE_INSTALL_BINDIR})

# XDG autostart — KDE phase 2 ensures Plasma shell is ready before the dock starts
install(FILES nix/plasma-dock.desktop
        DESTINATION ${KDE_INSTALL_AUTOSTARTDIR})
