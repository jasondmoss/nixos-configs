import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtWebEngine
import org.kde.kirigami as Kirigami

Kirigami.ApplicationWindow {
    id: root
    width: 2200
    height: 1300
    visible: Controller.visible
    title: "Proton Suite"

    WebEngineProfile {
        id: sharedProfile
        storageName: "proton"
        offTheRecord: false
        persistentCookiesPolicy: WebEngineProfile.ForcePersistentCookies
        httpCacheType: WebEngineProfile.DiskHttpCache

        Component.onCompleted: {
            var script = Qt.createQmlObject(
                'import QtWebEngine; WebEngineScript {}',
                sharedProfile
            );
            script.name = "proton-notification-bridge";
            script.injectionPoint = WebEngineScript.DocumentCreation;
            script.worldId = WebEngineScript.MainWorld;
            script.sourceCode = "
(function()
{
    if (window.__protonBridgeInstalled) {
        return;
    }
    window.__protonBridgeInstalled = true;

    function BridgedNotification(title, options)
    {
        var body = (options && options.body) ? options.body : '';
        window.open('proton-notify://?title=' + encodeURIComponent(title) +
            '&body=' + encodeURIComponent(body),
            '_blank', 'width=1,height=1'
        );
    }

    BridgedNotification.permission = 'granted';
    BridgedNotification.requestPermission = function(cb) {
        if (typeof cb === 'function') cb('granted');
        return Promise.resolve('granted');
    };
    window.Notification = BridgedNotification;
})();
            ";
            userScripts.insert(script);
        }
    }

    function handleNavigation(url)
    {
        let u = url.toString();
        if (u.match(/\.(svg|png|jpeg|jpg|gif|pdf|docx?|xlsx?|pptx?|zip|7z|tar\.gz|od[tsp])$/i)) {
            Qt.openUrlExternally(u);

            return;
        }
        if (u.includes("mail.proton.me")) {
            switchTab(0, u); return;
        }
        if (u.includes("calendar.proton.me")) {
            switchTab(1, u); return;
        }
        if (u.includes("drive.proton.me")) {
            switchTab(2, u); return;
        }
        if (u.includes("account.proton.me")) {
            stack.children[stack.currentIndex].url = u;

            return;
        }
        Qt.openUrlExternally(u);
    }

    function switchTab(index, url)
    {
        mainTabs.currentIndex = index;
        if (url) stack.children[index].url = url;
    }

    Shortcut {
        sequence: "Ctrl+Tab"
        onActivated: mainTabs.currentIndex =
            (mainTabs.currentIndex + 1) % mainTabs.count
    }
    Shortcut {
        sequence: "Ctrl+Shift+Tab"
        onActivated: mainTabs.currentIndex =
            (mainTabs.currentIndex - 1 + mainTabs.count) % mainTabs.count
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        TabBar {
            id: mainTabs
            Layout.fillWidth: true
            z: 1
            TabButton { text: "Mail" }
            TabButton { text: "Calendar" }
            TabButton { text: "Drive" }
        }

        StackLayout {
            id: stack
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: mainTabs.currentIndex

            ProtonTab {
                url: "https://mail.proton.me/"
                appProfile: sharedProfile
                expectedHost: "mail.proton.me"
            }
            ProtonTab {
                url: "https://calendar.proton.me/"
                appProfile: sharedProfile
                expectedHost: "calendar.proton.me"
            }
            ProtonTab {
                url: "https://drive.proton.me/"
                appProfile: sharedProfile
                expectedHost: "drive.proton.me"
            }
        }
    }
}
