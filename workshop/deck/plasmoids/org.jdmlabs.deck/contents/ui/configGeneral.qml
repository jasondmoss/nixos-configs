import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: page

    property alias cfg_port: portSpin.value
    property alias cfg_trackPhpStorm: trackCheck.checked
    property alias cfg_idleWhenNoProject: noProjectCheck.checked
    property alias cfg_idleWhenOffWork: offWorkCheck.checked

    QQC2.SpinBox {
        id: portSpin
        Kirigami.FormData.label: i18n("Agent port:")
        from: 1024
        to: 65535
        editable: true
        textFromValue: (value) => String(value)
    }

    QQC2.CheckBox {
        id: trackCheck
        Kirigami.FormData.label: i18n("PhpStorm:")
        text: i18n("Follow the project of the active PhpStorm window")
    }

    Item { Kirigami.FormData.isSection: true }

    QQC2.CheckBox {
        id: noProjectCheck
        Kirigami.FormData.label: i18n("Sleep:")
        text: i18n("Git and Gulp show a placeholder while no project is open")
    }

    QQC2.CheckBox {
        id: offWorkCheck
        text: i18n("CircleCI and Pantheon show a placeholder while no work project is open")
    }

    QQC2.Label {
        Kirigami.FormData.isSection: true
        text: i18n("Tokens (CIRCLE_TOKEN, TERMINUS_TOKEN) live in ~/.config/deck/secrets.env; the watcher, work roots and polling cadence belong to the deck-agent service.")
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
        font: Kirigami.Theme.smallFont
    }
}
