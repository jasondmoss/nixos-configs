import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtWebEngine
import org.kde.kirigami as Kirigami
import QtCore

Kirigami.ApplicationWindow {
    id: root
    width: 2000
    height: 1250
    visible: Controller.visible
    title: "Proton Suite"

    // Define profile in QML.
    property WebEngineProfile sharedProfile: WebEngineProfile {
        storageName: "proton"
        offTheRecord: false
        persistentCookiesPolicy: WebEngineProfile.ForcePersistentCookies
        httpCacheType: WebEngineProfile.DiskHttpCache
    }

    // Router Logic.
    function handleNavigation(url)
    {
        let u = url.toString();
        if (u.match(/\.(svg|png|jpeg|jpg|gif|pdf|docx?|xlsx?|pptx?|zip|7z|tar\.gz|od[tsp])$/i)) {
            Qt.openUrlExternally(u);

            return;
        }
        if (u.includes("mail.proton.me")) { switchTab(0, u); return; }
        if (u.includes("calendar.proton.me")) { switchTab(1, u); return; }
        if (u.includes("drive.proton.me")) { switchTab(2, u); return; }
        if (u.includes("docs.proton.me")) {
             if (stack.currentIndex !== 4) {
                 switchTab(3, u);
             } else {
                 switchTab(4, u);
             }

             return;
        }
        if (u.includes("lumo.proton.me")) { switchTab(5, u); return; }
        if (u.includes("pass.proton.me")) { switchTab(6, u); return; }
        if (u.includes("account.proton.me")) {
            stack.children[stack.currentIndex].url = u;

            return;
        }

        Qt.openUrlExternally(u);
    }

    function switchTab(index, url)
    {
        mainTabs.currentIndex = index;
        if (url) {
            stack.children[index].url = url;
        }
    }

    // Shortcuts.
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

    // Direct Layout.
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        TabBar {
            id: mainTabs
            Layout.fillWidth: true
            z: 1

            TabButton { text: "Mail"; onClicked: stack.currentIndex = 0 }
            TabButton { text: "Calendar"; onClicked: stack.currentIndex = 1 }
            TabButton { text: "Drive"; onClicked: stack.currentIndex = 2 }
            TabButton { text: "Docs"; onClicked: stack.currentIndex = 3 }
            TabButton { text: "Sheets"; onClicked: stack.currentIndex = 4 }
            TabButton { text: "Lumo"; onClicked: stack.currentIndex = 5 }
            TabButton { text: "Pass"; onClicked: stack.currentIndex = 6 }
        }

        StackLayout {
            id: stack
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: mainTabs.currentIndex

            ProtonTab {
                url: "https://mail.proton.me/";
                appProfile: root.sharedProfile;
                expectedHost: "mail.proton.me"
            }
            ProtonTab {
                url: "https://calendar.proton.me/";
                appProfile: root.sharedProfile;
                expectedHost: "calendar.proton.me"
            }
            ProtonTab {
                url: "https://drive.proton.me/";
                appProfile: root.sharedProfile;
                expectedHost: "drive.proton.me"
            }
            ProtonTab {
                url: "https://docs.proton.me/";
                appProfile: root.sharedProfile;
                expectedHost: "docs.proton.me"
            }
            ProtonTab {
                url: "https://docs.proton.me/";
                appProfile: root.sharedProfile;
                expectedHost: "docs.proton.me"
            }
            ProtonTab {
                url: "https://lumo.proton.me/";
                appProfile: root.sharedProfile;
                expectedHost: "lumo.proton.me"
            }
            ProtonTab {
                url: "https://pass.proton.me/";
                appProfile: root.sharedProfile;
                expectedHost: "pass.proton.me"
            }
        }
    }
}
