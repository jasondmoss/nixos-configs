import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import QtWebEngine

Kirigami.ApplicationWindow {
    id: root
    width: 1280
    height: 900
    visible: true
    title: "Proton Suite"

    // [ARCHITECTURAL FIX] Define Profile in QML
    WebEngineProfile {
        id: protonProfile

        // This maps to the folder C++ created:
        // ~/.local/share/Proton/Proton Suite/QtWebEngine/ProtonSession
        storageName: "ProtonSession"

        persistentCookiesPolicy: WebEngineProfile.ForcePersistentCookies
        httpCacheType: WebEngineProfile.DiskHttpCache

        httpUserAgent: "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36"

        // [MAGIC FIX] Force disable Incognito after initialization
        Component.onCompleted: {
            offTheRecord = false;
        }
    }

    onClosing: (close) => {
        close.accepted = false;
        root.hide();
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        QQC2.TabBar {
            id: navBar
            Layout.fillWidth: true
            QQC2.TabButton { text: "Mail"; icon.name: "mail-message-new" }
            QQC2.TabButton { text: "Calendar"; icon.name: "office-calendar" }
            QQC2.TabButton { text: "Lumo"; icon.name: "im-bot" }
            QQC2.TabButton { text: "Docs"; icon.name: "document-edit" }
            QQC2.TabButton { text: "Drive"; icon.name: "folder-cloud" }
        }

        StackLayout {
            currentIndex: navBar.currentIndex
            Layout.fillWidth: true
            Layout.fillHeight: true

            // PASS THE QML PROFILE TO VIEWS
            ProtonView {
                targetUrl: "https://mail.proton.me/u/5/inbox"
                webProfile: protonProfile
            }
            ProtonView {
                targetUrl: "https://calendar.proton.me/"
                webProfile: protonProfile
            }
            ProtonView {
                targetUrl: "https://lumo.proton.me/"
                webProfile: protonProfile
            }
            ProtonView {
                targetUrl: "https://docs.proton.me/u/5/recents"
                webProfile: protonProfile
            }
            ProtonView {
                targetUrl: "https://drive.proton.me/u/5/"
                webProfile: protonProfile
            }
        }
    }
}
