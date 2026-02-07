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
    settings.pluginsEnabled: true

    onFullScreenRequested: (request) => {
        request.accept();
    }

    onNavigationRequested: (request) => {
        if (request.navigationType === WebEngineNavigationRequest.LinkClicked) {
            let u = request.url.toString();

            /**
             * Allow navigation if it matches the tab's expected host (e.g.
             * clicking an email in Mail)
             *
             * OR if it is a sub-navigation (like settings)
             */
            if (u.includes(expectedHost)) {
                request.action = WebEngineNavigationRequest.AcceptRequest;
            } else {
                request.action = WebEngineNavigationRequest.IgnoreRequest;
                /**
                 * Forward external links to the Main Router
                 * We use the parent chain:
                 *      (StackLayout)
                 *          -> parent (ColumnLayout)
                 *          -> parent (Page)
                 *          -> parent (Window)
                 *
                 * OR simpler: access the global 'root' id if it's in the same
                 * engine context.
                 */
                root.handleNavigation(request.url);
            }
        }
    }

    onNewWindowRequested: (request) => {
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
