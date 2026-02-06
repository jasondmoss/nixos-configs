import QtQuick
import QtWebEngine
import org.kde.kirigami as Kirigami

Kirigami.ApplicationWindow {
    id: root
    width: 1000
    height: 800
    visible: true
    title: "Gemini"

    WebEngineView {
        anchors.fill: parent
        url: "https://gemini.google.com/"

        // Enabling hardware acceleration and desktop-like features
        settings.javascriptCanAccessClipboard: true
        settings.playbackRequiresUserGesture: false
    }

    // Override the close button to minimize to tray instead
    onClosing: (close) => {
        close.accepted = false;
        root.visible = false;
    }
}
