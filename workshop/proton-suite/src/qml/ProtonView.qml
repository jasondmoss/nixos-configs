import QtQuick
import QtWebEngine
import QtQuick.Controls as QQC2

WebEngineView {
    id: webView

    required property url targetUrl
    // We explicitly require the profile object from Main.qml
    required property WebEngineProfile webProfile

    url: targetUrl
    profile: webProfile

    settings.javascriptEnabled: true
    settings.localStorageEnabled: true
    settings.pluginsEnabled: true
    settings.javascriptCanOpenWindows: true
    settings.allowRunningInsecureContent: false

    onFeaturePermissionRequested: (securityOrigin, feature) => {
        if (feature === WebEngineView.Notifications) {
            const originStr = securityOrigin.toString();
            if (originStr.includes("proton.me")) {
                webView.grantFeaturePermission(securityOrigin, feature, true);
            } else {
                webView.grantFeaturePermission(securityOrigin, feature, false);
            }
        }
    }

    onNewWindowRequested: (request) => {
        Qt.openUrlExternally(request.requestedUrl);
    }

    // [FIX] New API for Qt 6.8+
    onNavigationRequested: (request) => {
        const urlString = request.url.toString();
        if (urlString.includes("proton.me")) {
            // FIX: Method call 'accept()', NOT property 'action = ...'
            request.accept();
        } else {
            // FIX: Method call 'reject()'
            request.reject();
            Qt.openUrlExternally(request.url);
        }
    }

    QQC2.ProgressBar {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        visible: webView.loading
        value: webView.loadProgress / 100
        height: 4
        opacity: webView.loading ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 200 } }
    }
}
