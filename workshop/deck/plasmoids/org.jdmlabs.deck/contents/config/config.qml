import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: i18n("General")
        icon: "preferences-desktop-plasma"
        source: "configGeneral.qml"
    }
    ConfigCategory {
        name: i18n("Git & Gulp")
        icon: "vcs-normal"
        source: "configProject.qml"
    }
    ConfigCategory {
        name: i18n("CircleCI & Pantheon")
        icon: "network-server"
        source: "configDeploy.qml"
    }
}
