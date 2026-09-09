import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: root

    property alias cfg_colorMode: colorModeCombo.currentIndex
    property alias cfg_customColor: hexField.text
    property alias cfg_textShadow: shadowCheck.checked
    property alias cfg_netInterface: netField.text
    property alias cfg_updateInterval: intervalSpin.value

    QQC2.ComboBox {
        id: colorModeCombo
        Kirigami.FormData.label: i18n("Text color:")
        model: [
            i18n("Automatic from wallpaper"),
            i18n("Always white"),
            i18n("Always black"),
            i18n("Custom")
        ]
    }

    RowLayout {
        Kirigami.FormData.label: i18n("Custom color:")
        enabled: colorModeCombo.currentIndex === 3

        QQC2.TextField {
            id: hexField
            placeholderText: "#ffffff"
            inputMask: "\\#HHHHHH"
            Layout.preferredWidth: Kirigami.Units.gridUnit * 6
        }

        Rectangle {
            width: Kirigami.Units.gridUnit * 1.5
            height: width
            radius: 3
            border.width: 1
            border.color: Qt.rgba(0.5, 0.5, 0.5, 0.7)
            color: /^#[0-9A-Fa-f]{6}$/.test(hexField.text)
                ? hexField.text
                : "transparent"
        }
    }

    QQC2.CheckBox {
        id: shadowCheck
        Kirigami.FormData.label: i18n("Legibility:")
        text: i18n("Contrasting text shadow")
    }

    Item {
        Kirigami.FormData.isSection: true
    }

    QQC2.TextField {
        id: netField
        Kirigami.FormData.label: i18n("Network interface:")
        placeholderText: "wlp5s0"
    }

    QQC2.SpinBox {
        id: intervalSpin
        Kirigami.FormData.label: i18n("Refresh interval (s):")
        from: 1
        to: 30
    }
}
