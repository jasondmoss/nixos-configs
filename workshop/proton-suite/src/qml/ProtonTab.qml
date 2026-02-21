import QtQuick
import QtWebEngine
import QtQuick.Controls

WebEngineView {
    id: webView

    property WebEngineProfile appProfile
    property string expectedHost: ""

    profile: appProfile

    settings.javascriptEnabled: true
    settings.localStorageEnabled: true
    settings.javascriptCanOpenWindows: true

    onFullScreenRequested: (request) => {
        request.accept();
    }

    onNavigationRequested: (request) => {
        if (request.navigationType === WebEngineNavigationRequest.LinkClicked) {
            let u = request.url.toString();
            if (u.includes(expectedHost)) {
                request.action = WebEngineNavigationRequest.AcceptRequest;
            } else {
                request.action = WebEngineNavigationRequest.IgnoreRequest;
                root.handleNavigation(request.url);
            }
        }
    }

    onNewWindowRequested: (request) => {
        let u = request.requestedUrl.toString();
        if (u.startsWith("proton-notify://")) {
            let query = u.split("?")[1] || "";
            let params = {};
            query.split("&").forEach(function(pair) {
                let parts = pair.split("=");
                if (parts.length >= 2) {
                    params[parts[0]] = decodeURIComponent(parts.slice(1).join("="));
                }
            });

            Controller.showNotification(
                params["title"] || "",
                params["body"]  || ""
            );

            return;
        }

        root.handleNavigation(request.requestedUrl);
    }

    onFeaturePermissionRequested: (securityOrigin, feature) => {
        if (feature === WebEngineView.Notifications ||
            feature === WebEngineView.DesktopAudioVideoCapture
        ) {
            grantFeaturePermission(securityOrigin, feature, true);
        } else {
            grantFeaturePermission(securityOrigin, feature, false);
        }
    }
}
