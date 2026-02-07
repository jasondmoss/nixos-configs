#!/usr/bin/env python3
import sys
import os
import signal
from PyQt6.QtWidgets import QApplication, QSystemTrayIcon, QMenu, QMainWindow
from PyQt6.QtWebEngineWidgets import QWebEngineView
from PyQt6.QtWebEngineCore import QWebEngineProfile, QWebEnginePage, QWebEngineScript, QWebEngineSettings
from PyQt6.QtGui import QIcon, QAction, QDesktopServices, QKeySequence
from PyQt6.QtCore import QUrl, Qt
import dbus
import dbus.service
from dbus.mainloop.glib import DBusGMainLoop

APP_NAME = "Gemini Desktop"
APP_ID = "gemini-desktop"
USER_AGENT = "Mozilla/5.0 (X11; Linux x86_64; rv:134.0) Gecko/20100101 Firefox/134.0"
START_URL = "https://gemini.google.com"
ICON_PATH = os.path.join(os.path.dirname(__file__), "gemini-desktop.svg")
STORAGE_PATH = os.path.expanduser(f"~/.local/share/{APP_ID}")

class GeminiWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle(APP_NAME)
        self.resize(1200, 1600)
        self.setWindowIcon(QIcon(ICON_PATH))

        # Setup Persistence
        self.profile = QWebEngineProfile(APP_ID, self)
        self.profile.setPersistentStoragePath(STORAGE_PATH)
        self.profile.setPersistentCookiesPolicy(QWebEngineProfile.PersistentCookiesPolicy.ForcePersistentCookies)
        self.profile.setHttpUserAgent(USER_AGENT)

        # Inject JS to clean up the environment
        self.inject_gecko_spoof()

        # Setup Web View
        self.webview = QWebEngineView()
        self.webview.setPage(GeminiPage(self.profile, self.webview))

        # This allows navigator.clipboard.writeText to function
        settings = self.webview.settings()
        settings.setAttribute(QWebEngineSettings.WebAttribute.JavascriptCanAccessClipboard, True)
        settings.setAttribute(QWebEngineSettings.WebAttribute.JavascriptCanPaste, True)

        self.setCentralWidget(self.webview)
        self.webview.load(QUrl(START_URL))

    def inject_gecko_spoof(self):
        script = QWebEngineScript()
        s_code = """
Object.defineProperty(navigator, 'webdriver', { get: () => undefined });
        """
        script.setSourceCode(s_code)
        script.setName("gecko_spoof")
        script.setWorldId(QWebEngineScript.ScriptWorldId.MainWorld)
        script.setInjectionPoint(QWebEngineScript.InjectionPoint.DocumentCreation)
        script.setRunsOnSubFrames(True)
        self.profile.scripts().insert(script)

    def closeEvent(self, event):
        event.ignore()
        self.hide()

class GeminiPage(QWebEnginePage):
    def __init__(self, profile, parent):
        super().__init__(profile, parent)

    def permissionRequested(self, permission_origin, feature):
        # We approve Notifications, ClipboardRead, and ClipboardWrite.
        if feature in [
            QWebEnginePage.Feature.Notifications,
            QWebEnginePage.Feature.ClipboardRead,
            QWebEnginePage.Feature.ClipboardWrite
        ]:
            self.setFeaturePermission(
                permission_origin,
                feature,
                QWebEnginePage.PermissionPolicy.PermissionGrantedByUser
            )
        else:
            # Deny others (Geoloc, Mic, Camera) for privacy.
            self.setFeaturePermission(
                permission_origin,
                feature,
                QWebEnginePage.PermissionPolicy.PermissionDeniedByUser
            )

    def javaScriptConsoleMessage(self, level, msg, line, source):
        pass

    def createWindow(self, _type):
        page = GeminiPage(self.profile(), self)
        page.urlChanged.connect(self.on_url_changed)
        return page

    def on_url_changed(self, url):
        u_str = url.toString()
        if "google.com" not in u_str and "gstatic.com" not in u_str:
            QDesktopServices.openUrl(url)
            self.deleteLater()

class GeminiApp(QApplication):
    def __init__(self, argv):
        super().__init__(argv)
        self.setQuitOnLastWindowClosed(False)
        self.window = GeminiWindow()

        self.tray_icon = QSystemTrayIcon(QIcon(ICON_PATH), self)
        self.tray_icon.setToolTip(APP_NAME)

        self.menu = QMenu()
        self.action_toggle = QAction("Show/Hide", self)
        self.action_toggle.triggered.connect(self.toggle_window)
        self.action_quit = QAction("Quit", self)
        self.action_quit.triggered.connect(self.quit_app)

        self.menu.addAction(self.action_toggle)
        self.menu.addSeparator()
        self.menu.addAction(self.action_quit)
        self.tray_icon.setContextMenu(self.menu)

        self.tray_icon.activated.connect(self.on_tray_click)
        self.tray_icon.show()

        self.setup_global_shortcut()
        self.window.show()

    def on_tray_click(self, reason):
        if reason == QSystemTrayIcon.ActivationReason.Trigger:
            self.toggle_window()

    def toggle_window(self, _=None):
        if self.window.isVisible():
            if self.window.isActiveWindow():
                self.window.hide()
            else:
                self.window.activateWindow()
                self.window.raise_()
        else:
            self.window.show()
            self.window.activateWindow()
            self.window.raise_()

    def quit_app(self):
        if self.window.webview.page():
            self.window.webview.setPage(None)
        self.window.close()
        self.quit()

    def setup_global_shortcut(self):
        try:
            bus = dbus.SessionBus()
            kglobalaccel = bus.get_object("org.kde.kglobalaccel", "/kglobalaccel")

            component = "gemini-desktop"
            action_name = "toggle"
            friendly_name = "Toggle Gemini Desktop"

            kglobalaccel.doRegister([component, action_name, friendly_name],
                                    dbus_interface="org.kde.KGlobalAccel")

            key_seq = QKeySequence("Meta+Z")
            key_int = key_seq[0].toCombined()

            kglobalaccel.setShortcut(
                [component, action_name],
                [key_int],
                0,
                dbus_interface="org.kde.KGlobalAccel"
            )

            bus.add_signal_receiver(
                self.on_shortcut_triggered,
                dbus_interface="org.kde.kglobalaccel.Component",
                signal_name="globalShortcutPressed"
            )
        except Exception as e:
            print(f"Failed to register global shortcut: {e}")

    def on_shortcut_triggered(self, component, action, timestamp):
        if component == "gemini-desktop" and action == "toggle":
            self.toggle_window()

if __name__ == "__main__":
    signal.signal(signal.SIGINT, signal.SIG_DFL)
    os.environ["QT_AUTO_SCREEN_SCALE_FACTOR"] = "1"
    DBusGMainLoop(set_as_default=True)
    app = GeminiApp(sys.argv)
    sys.exit(app.exec())
