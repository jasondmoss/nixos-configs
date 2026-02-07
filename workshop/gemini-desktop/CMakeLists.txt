cmake_minimum_required(VERSION 3.16)

project(gemini-desktop VERSION 1.0)

set(QT_MIN_VERSION "6.6.0")
set(KF_MIN_VERSION "6.0.0")

# Find Dependencies
find_package(ECM ${KF_MIN_VERSION} REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH})

include(KDEInstallDirs)
include(KDECMakeSettings)
include(KDECompilerSettings NO_POLICY_SCOPE)
include(FeatureSummary)

find_package(Qt6 ${QT_MIN_VERSION} REQUIRED COMPONENTS
    Core
    Gui
    Qml
    QuickControls2
    WebEngineQuick
)

find_package(KF6 ${KF_MIN_VERSION} REQUIRED COMPONENTS
    StatusNotifierItem
    Kirigami
    GlobalAccel
)

# Define Sources
set(gemini_SRCS
    main.cpp
    resources.qrc # You'll need this to bundle the QML
)

# Executable & Linking
add_executable(gemini-desktop ${gemini_SRCS})

target_link_libraries(gemini-desktop
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::QuickControls2
    Qt6::WebEngineQuick
    KF6::StatusNotifierItem
    KF6::Kirigami
    KF6::GlobalAccel
)

install(TARGETS gemini-desktop ${KDE_INSTALL_TARGETS_DEFAULT_ARGS})
