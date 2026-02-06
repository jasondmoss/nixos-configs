import QtQuick
import QtWebEngine
import org.kde.kirigami as Kirigami
import QtQuick.Controls as Controls
import QtQuick.Layouts

Kirigami.ApplicationWindow {
    id: root
    width: 1280
    height: 1000
    visible: true
    title: "Gemini"

    pageStack.initialPage: Kirigami.Page {
        // Dynamic Title.
        title: webView.title != "" ? webView.title : "Google Gemini"

        // Remove Padding for full-width browser.
        leftPadding: 0
        rightPadding: 0
        topPadding: 0
        bottomPadding: 0

        // Actions (The "Toolbar" buttons).
        // actions: [
        //     Kirigami.Action {
        //         icon.name: "go-previous"
        //         text: "Back"
        //         visible: webView.canGoBack
        //         onTriggered: webView.goBack()
        //     },
        //     Kirigami.Action {
        //         icon.name: "go-next"
        //         text: "Forward"
        //         visible: webView.canGoForward
        //         onTriggered: webView.goForward()
        //     },
        //     Kirigami.Action {
        //         icon.name: "view-refresh"
        //         text: "Refresh"
        //         onTriggered: webView.reload()
        //     },
        //     Kirigami.Action {
        //         icon.name: "go-home"
        //         text: "Home"
        //         onTriggered: webView.url = "https://gemini.google.com/"
        //     }
        // ]

        // Content.
        contentItem: WebEngineView {
            id: webView

            // Connect to the shared C++ profile.
            profile: WebEngineProfile {
                storageName: "GeminiShared"
                offTheRecord: false
            }

            url: "https://gemini.google.com/"

            settings.localStorageEnabled: true
            settings.javascriptEnabled: true
            settings.autoLoadImages: true

            onNewWindowRequested: (request) => {
                Qt.openUrlExternally(request.requestedUrl);
            }
        }
    }

    onClosing: (close) => {
        close.accepted = false;
        root.visible = false;
    }
}
