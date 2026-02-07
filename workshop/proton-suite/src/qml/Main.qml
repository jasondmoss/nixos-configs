import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtWebEngine
import org.kde.kirigami as Kirigami
import QtCore

Kirigami.ApplicationWindow {
    id: root
    width: 2480
    height: 1500
    visible: true
    title: "Proton Suite"

    property WebEngineProfile sharedProfile: WebEngineProfile {
        storageName: "proton"
        offTheRecord: false
        persistentCookiesPolicy: WebEngineProfile.ForcePersistentCookies
        httpCacheType: WebEngineProfile.DiskHttpCache
    }

    /**
     * Handles navigation based on the provided URL. Determines the appropriate
     * behavior (such as opening the URL externally or switching to a specific
     * application tab) depending on the URL's content or domain.
     *
     * @param {string} url
     *      The URL to handle for navigation. It can be an external link or an
     *      application-specific link supported by the system.
     * @return {void}
     *      This method does not return any value. Its actions are carried out
     *      through side effects such as switching tabs or opening URLs.
     */
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

    /**
     * Switches the active tab in the application and optionally updates its
     * content URL.
     *
     * @param {number} index
     *      The index of the tab to switch to.
     * @param {string} [url]
     *      An optional URL to update the content of the specified tab.
     * @return {void}
     *      This function does not return any value.
     */
    function switchTab(index, url)
    {
        // Update the TabBar, StackLayout follows.
        mainTabs.currentIndex = index;

        if (url) {
            stack.children[index].url = url;
        }
    }

    /**
     * Cycle Tabs (Ctrl+Tab).
     */
    Shortcut {
        sequence: "Ctrl+Tab"
        onActivated: {
            // Calculate next index with wrap-around.
            let nextIndex = (mainTabs.currentIndex + 1) % mainTabs.count;
            mainTabs.currentIndex = nextIndex;
        }
    }

    /**
     * Cycle Backwards (Ctrl+Shift+Tab)
     */
    Shortcut {
        sequence: "Ctrl+Shift+Tab"
        onActivated: {
            // Calculate previous index with wrap-around
            let prevIndex = (mainTabs.currentIndex - 1 + mainTabs.count) % mainTabs.count;
            mainTabs.currentIndex = prevIndex;
        }
    }

    pageStack.initialPage: Kirigami.Page {
        padding: 0
        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            TabBar {
                id: mainTabs
                Layout.fillWidth: true
                z: 1

                // Mail (0) -> Ctrl+1
                TabButton {
                    text: "Mail";
                    onClicked: stack.currentIndex = 0
                }
                // Calendar (1) -> Ctrl+2
                TabButton {
                    text: "Calendar";
                    onClicked: stack.currentIndex = 1
                }
                // Drive (2) -> Ctrl+3
                TabButton {
                    text: "Drive";
                    onClicked: stack.currentIndex = 2
                }
                // Docs (3) -> Ctrl+4
                TabButton {
                    text: "Docs";
                    onClicked: stack.currentIndex = 3
                }
                // Sheets (4) -> Ctrl+5
                TabButton {
                    text: "Sheets";
                    onClicked: stack.currentIndex = 4
                }
                // Lumo (5) -> Ctrl+6
                TabButton {
                    text: "Lumo";
                    onClicked: stack.currentIndex = 5
                }
                // Pass (6) -> Ctrl+7
                TabButton {
                    text: "Pass";
                    onClicked: stack.currentIndex = 6
                }
            }

            StackLayout {
                id: stack
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: mainTabs.currentIndex

                ProtonTab {
                    url: "https://mail.proton.me/";
                    profile: root.sharedProfile;
                    expectedHost: "mail.proton.me"
                }
                ProtonTab {
                    url: "https://calendar.proton.me/";
                    profile: root.sharedProfile;
                    expectedHost: "calendar.proton.me"
                }
                ProtonTab {
                    url: "https://drive.proton.me/";
                    profile: root.sharedProfile;
                    expectedHost: "drive.proton.me"
                }
                ProtonTab {
                    url: "https://docs.proton.me/";
                    profile: root.sharedProfile;
                    expectedHost: "docs.proton.me"
                }
                ProtonTab {
                    url: "https://docs.proton.me/";
                    profile: root.sharedProfile;
                    expectedHost: "docs.proton.me"
                }
                ProtonTab {
                    url: "https://lumo.proton.me/";
                    profile: root.sharedProfile;
                    expectedHost: "lumo.proton.me"
                }
                ProtonTab {
                    url: "https://pass.proton.me/";
                    profile: root.sharedProfile;
                    expectedHost: "pass.proton.me"
                }
            }
        }
    }
}
