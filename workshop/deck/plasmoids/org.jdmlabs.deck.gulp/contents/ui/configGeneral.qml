import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: page

    property alias cfg_port: portSpin.value
    property alias cfg_trackPhpStorm: trackCheck.checked
    property alias cfg_fontSize: fontSpin.value
    property alias cfg_wrapLines: wrapCheck.checked
    property alias cfg_maxLines: linesSpin.value

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

    QQC2.SpinBox {
        id: fontSpin
        Kirigami.FormData.label: i18n("Log font size:")
        from: 7
        to: 24
        textFromValue: (value) => i18n("%1 px", value)
        valueFromText: (text) => parseInt(text)
    }

    QQC2.CheckBox {
        id: wrapCheck
        Kirigami.FormData.label: i18n("Log:")
        text: i18n("Wrap long lines")
    }

    QQC2.SpinBox {
        id: linesSpin
        Kirigami.FormData.label: i18n("Lines kept:")
        from: 50
        to: 2000
        stepSize: 50
        editable: true
    }

    QQC2.Label {
        Kirigami.FormData.isSection: true
        text: i18n("The watcher itself (node, task, auto-start) is configured in the deck-agent service: ~/.config/deck/config.json.")
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
        font: Kirigami.Theme.smallFont
    }
}
