import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtWebEngine
import org.kde.kirigami as Kirigami
import QtCore

Kirigami.ApplicationWindow
{
    id: root
    width: 2480
    height: 1500
    visible: true
    title: "Proton Suite"

    property WebEngineProfile sharedProfile: WebEngineProfile
    {
        storageName: "proton"
        offTheRecord: false
        persistentCookiesPolicy: WebEngineProfile.ForcePersistentCookies
        httpCacheType: WebEngineProfile.DiskHttpCache
    }

    /**
     * Central Router Logic.
     *
     * * @param {object} url
     */
    function handleNavigation(url)
    {
        let u = url.toString();

        // FILE TYPE CHECK (SVG, PDF, Docs) -> System XDG App
        if (u.match(/\.(svg|jpg|jpeg|png|gif|pdf|docx?|xlsx?|pptx?|zip|7z|tar\.gz|od[tsp])$/i)) {
            Qt.openUrlExternally(u);

            return;
        }

        // Check which service the URL belongs to and switch tabs.
        if (u.includes("mail.proton.me")) {
            switchTab(0, u);

            return;
        }

        if (u.includes("calendar.proton.me")) {
            switchTab(1, u);

            return;
        }

        if (u.includes("drive.proton.me")) {
            switchTab(2, u);

            return;
        }

        /**
         * Docs & Sheets often share the same domain or sub-paths, strictly
         * routing them can be tricky if they don't have unique subdomains.
         *
         * Assuming standard proton subdomains:
         */
        if (u.includes("docs.proton.me")) {
             // Simple heuristic: if we are already in Sheets (4), stay there,
             // else go to Docs (3).
             if (stack.currentIndex !== 4) {
                 switchTab(3, u);
             } else {
                 switchTab(4, u);
             }

             return;
        }

        if (u.includes("lumo.proton.me")) {
            switchTab(5, u);

            return;
        }

        if (u.includes("pass.proton.me")) {
            switchTab(6, u);

            return;
        }

        if (u.includes("account.proton.me")) {
            // Allow account settings to open in the current tab.
            stack.children[stack.currentIndex].url = u;

            return;
        }

        // Everything elkse opens in the Default Browser.
        Qt.openUrlExternally(u);
    }

    /**
     * Helper to switch and load.
     *
     * @param {number} index
     * @param {string} url
     */
    function switchTab(index, url)
    {
        stack.currentIndex = index;

        // Load the specific requested URL in that tab.
        stack.children[index].url = url;
    }

    pageStack.initialPage: Kirigami.Page
    {
        padding: 0
        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            TabBar {
                id: mainTabs
                Layout.fillWidth: true
                z: 1
                TabButton {
                    text: "Mail";
                    onClicked: stack.currentIndex = 0
                }

                TabButton {
                    text: "Calendar";
                    onClicked: stack.currentIndex = 1
                }

                TabButton {
                    text: "Drive";
                    onClicked: stack.currentIndex = 2
                }

                TabButton {
                    text: "Docs";
                    onClicked: stack.currentIndex = 3
                }

                TabButton {
                    text: "Sheets";
                    onClicked: stack.currentIndex = 4
                }

                TabButton {
                    text: "Lumo";
                    onClicked: stack.currentIndex = 5
                }

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

                // We pass 'expectedHost' to help the tab know if a link
                // belongs to itself.
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
}
