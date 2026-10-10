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
    property alias cfg_maxPipelines: maxSpin.value
    property alias cfg_showJobs: jobsCheck.checked
    property alias cfg_showSubject: subjectCheck.checked

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
        from: 2
        to: 300
        editable: true
        textFromValue: (value) => i18np("%1 second", "%1 seconds", value)
        valueFromText: (text) => parseInt(text)
    }

    Item { Kirigami.FormData.isSection: true }

    QQC2.SpinBox {
        id: maxSpin
        Kirigami.FormData.label: i18n("Pipelines listed:")
        from: 1
        to: 20
    }

    QQC2.CheckBox {
        id: jobsCheck
        Kirigami.FormData.label: i18n("Details:")
        text: i18n("List jobs of workflows that are running or failed")
    }

    QQC2.CheckBox {
        id: subjectCheck
        text: i18n("Show the commit subject")
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
        text: i18n("The organisation, the CircleCI token (CIRCLE_TOKEN in ~/.config/deck/secrets.env) and the polling cadence belong to the deck-agent service.")
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
        font: Kirigami.Theme.smallFont
    }
}
