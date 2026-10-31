import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: page

    property alias cfg_ciInterval: ciIntervalSpin.value
    property alias cfg_maxPipelines: maxSpin.value
    property alias cfg_showJobs: jobsCheck.checked
    property alias cfg_showSubject: subjectCheck.checked
    property alias cfg_pantheonInterval: panIntervalSpin.value
    property alias cfg_follow: followCombo.currentIndex
    property alias cfg_pinnedSite: siteField.text
    property alias cfg_maxWorkflows: workflowSpin.value

    Item { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("CircleCI") }

    QQC2.SpinBox {
        id: ciIntervalSpin
        Kirigami.FormData.label: i18n("Refresh every:")
        from: 2
        to: 300
        editable: true
        textFromValue: (value) => i18np("%1 second", "%1 seconds", value)
        valueFromText: (text) => parseInt(text)
    }

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

    Item { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Pantheon") }

    QQC2.SpinBox {
        id: panIntervalSpin
        Kirigami.FormData.label: i18n("Refresh every:")
        from: 3
        to: 600
        editable: true
        textFromValue: (value) => i18np("%1 second", "%1 seconds", value)
        valueFromText: (text) => parseInt(text)
    }

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
}
