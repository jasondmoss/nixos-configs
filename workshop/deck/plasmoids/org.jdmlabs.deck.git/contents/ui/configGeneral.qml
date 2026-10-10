import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: page

    property alias cfg_port: portSpin.value
    property alias cfg_interval: intervalSpin.value
    property alias cfg_trackPhpStorm: trackCheck.checked
    property alias cfg_showUntracked: untrackedCheck.checked
    property alias cfg_showPath: pathCheck.checked

    QQC2.SpinBox {
        id: portSpin
        Kirigami.FormData.label: i18n("Agent port:")
        from: 1024
        to: 65535
        editable: true
        textFromValue: (value) => String(value)
    }

    QQC2.SpinBox {
        id: intervalSpin
        Kirigami.FormData.label: i18n("Refresh every:")
        from: 1
        to: 120
        editable: true
        textFromValue: (value) => i18np("%1 second", "%1 seconds", value)
        valueFromText: (text) => parseInt(text)
    }

    Item { Kirigami.FormData.isSection: true }

    QQC2.CheckBox {
        id: trackCheck
        Kirigami.FormData.label: i18n("PhpStorm:")
        text: i18n("Follow the project of the active PhpStorm window")
    }

    QQC2.CheckBox {
        id: untrackedCheck
        Kirigami.FormData.label: i18n("Files:")
        text: i18n("List untracked files")
    }

    QQC2.CheckBox {
        id: pathCheck
        text: i18n("Show the project path under the title")
    }
}
