import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: page

    property alias cfg_gitInterval: gitIntervalSpin.value
    property alias cfg_showUntracked: untrackedCheck.checked
    property alias cfg_showPath: pathCheck.checked
    property alias cfg_fontSize: fontSpin.value
    property alias cfg_wrapLines: wrapCheck.checked
    property alias cfg_maxLines: linesSpin.value

    Item { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Git") }

    QQC2.SpinBox {
        id: gitIntervalSpin
        Kirigami.FormData.label: i18n("Refresh every:")
        from: 1
        to: 120
        editable: true
        textFromValue: (value) => i18np("%1 second", "%1 seconds", value)
        valueFromText: (text) => parseInt(text)
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

    Item { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Gulp") }

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
}
