import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: page

    property alias cfg_port: portSpin.value
    property alias cfg_trackPhpStorm: trackCheck.checked
    property alias cfg_idleWhenOffWork: idleCheck.checked
    property alias cfg_interval: intervalSpin.value
    property alias cfg_follow: followCombo.currentIndex
    property alias cfg_pinnedSite: siteField.text
    property alias cfg_maxWorkflows: workflowSpin.value

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
        from: 3
        to: 600
        editable: true
        textFromValue: (value) => i18np("%1 second", "%1 seconds", value)
        valueFromText: (text) => parseInt(text)
    }

    Item { Kirigami.FormData.isSection: true }

    QQC2.ComboBox {
        id: followCombo
        Kirigami.FormData.label: i18n("Show the site of:")
        model: [
            i18n("Your latest CircleCI pipeline"),
            i18n("The project open in PhpStorm"),
            i18n("A fixed site")
        ]
    }

    QQC2.TextField {
        id: siteField
        Kirigami.FormData.label: i18n("Site name:")
        enabled: followCombo.currentIndex === 2
        placeholderText: i18n("e.g. castlehillinn")
    }

    QQC2.SpinBox {
        id: workflowSpin
        Kirigami.FormData.label: i18n("Workflows listed:")
        from: 1
        to: 30
    }

    Item { Kirigami.FormData.isSection: true }

    QQC2.CheckBox {
        id: idleCheck
        Kirigami.FormData.label: i18n("Off the clock:")
        text: i18n("Show a placeholder while no work project is open and Chrome is not running")
    }

    QQC2.CheckBox {
        id: trackCheck
        text: i18n("Report PhpStorm's open projects to the agent")
    }

    QQC2.Label {
        Kirigami.FormData.isSection: true
        text: i18n("terminus needs a machine token: TERMINUS_TOKEN in ~/.config/deck/secrets.env, or `terminus auth:login --machine-token=…` once.")
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
        font: Kirigami.Theme.smallFont
    }
}
