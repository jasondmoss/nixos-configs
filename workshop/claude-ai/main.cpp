/**
 * Claude AI — KDE Plasma PWA Wrapper
 *
 * A native Qt 6 / KDE Frameworks 6 wrapper for https://claude.ai/
 * with system tray integration, desktop notifications, and clipboard support.
 *
 * @url     https://claude.ai/
 * @license GPL-3.0-or-later
 */

#include <QApplication>
#include <QMainWindow>
#include <QToolBar>
#include <QLineEdit>
#include <QWebEngineView>
#include <QWebEngineProfile>
#include <QWebEnginePage>
#include <QWebEngineSettings>
#include <QWebEngineNavigationRequest>
#include <QWebEngineNotification>
#include <QWebEnginePermission>
#include <KStatusNotifierItem>
#include <KNotification>
#include <KGlobalAccel>
#include <QAction>
#include <QCloseEvent>
#include <QMenu>
#include <QIcon>
#include <QStandardPaths>
#include <QStringLiteral>
#include <QUrl>
#include <QDir>
#include <QDesktopServices>
#include <QToolTip>


// ---------------------------------------------------------------------------
//  Main window — hide-to-tray on close instead of quit.
// ---------------------------------------------------------------------------
class ClaudeWindow : public QMainWindow
{
    public:
        using QMainWindow::QMainWindow;

    protected:
        void closeEvent(QCloseEvent *event) override
        {
            event->ignore();
            hide();
        }
};


// ---------------------------------------------------------------------------
//  Notification bridge — routes QWebEngineNotification → KNotification.
// ---------------------------------------------------------------------------
static void presentNotification(std::unique_ptr<QWebEngineNotification> wn)
{
    auto *kn = new KNotification(QStringLiteral("webNotification"));
    kn->setTitle(wn->title());
    kn->setText(wn->message());
    kn->setIconName(QStringLiteral("claude-ai"));

    QWebEngineNotification *raw = wn.release();

    auto *defaultAction = kn->addDefaultAction(QStringLiteral("Open"));
    QObject::connect(defaultAction, &KNotificationAction::activated, raw, [raw]() {
        raw->click();
    });
    QObject::connect(kn, &KNotification::closed, raw, [raw]() {
        raw->close();
        raw->deleteLater();
    });
    QObject::connect(raw, &QWebEngineNotification::closed, kn, [kn, raw]() {
        kn->close();
        raw->deleteLater();
    });

    kn->sendEvent();
}


// ---------------------------------------------------------------------------
//  Entry point
// ---------------------------------------------------------------------------
int main(int argc, char *argv[])
{
    // Suppress noisy-but-harmless Chromium warnings (Permissions-Policy, etc.).
    qputenv("QTWEBENGINE_CHROMIUM_FLAGS", "--log-level=3");

    QApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("claude-ai"));
    app.setApplicationDisplayName(QStringLiteral("Claude AI"));
    app.setWindowIcon(QIcon::fromTheme(QStringLiteral("claude-ai")));
    app.setQuitOnLastWindowClosed(false);

    // --- Persistent storage (cookies, localStorage, IndexedDB) ---
    const QString appDataPath = QStandardPaths::writableLocation(
        QStandardPaths::AppDataLocation
    );
    const QString storagePath = appDataPath + QStringLiteral("/webengine");
    QDir().mkpath(storagePath);

    auto *profile = new QWebEngineProfile(
        QStringLiteral("claude-storage"), &app
    );
    profile->setPersistentStoragePath(storagePath);
    profile->setPersistentCookiesPolicy(
        QWebEngineProfile::ForcePersistentCookies
    );

    // Route web notifications through our KNotification bridge.
    profile->setNotificationPresenter(&presentNotification);

    // --- Main window with URL bar ---
    auto *window = new ClaudeWindow();
    window->setWindowTitle(QStringLiteral("Claude AI"));
    window->resize(1700, 1200);

    // URL bar in a non-movable toolbar.
    auto *navBar = new QToolBar(QStringLiteral("Navigation"), window);
    navBar->setMovable(false);
    navBar->setFloatable(false);
    navBar->setContextMenuPolicy(Qt::PreventContextMenu);

    auto *urlBar = new QLineEdit(navBar);
    urlBar->setPlaceholderText(QStringLiteral("Enter URL..."));
    urlBar->setClearButtonEnabled(true);
    navBar->addWidget(urlBar);

    window->addToolBar(navBar);

    // --- Web view (central widget, parented to window) ---
    auto *view = new QWebEngineView(window);
    auto *page = new QWebEnginePage(profile, view);
    view->setPage(page);
    window->setCentralWidget(view);

    // Enable clipboard read/write and local storage.
    auto *settings = view->settings();
    settings->setAttribute(QWebEngineSettings::LocalStorageEnabled, true);
    settings->setAttribute(QWebEngineSettings::JavascriptCanAccessClipboard, true);
    settings->setAttribute(QWebEngineSettings::JavascriptCanPaste, true);

    // --- URL bar wiring ---
    // Navigate on Enter.
    QObject::connect(urlBar, &QLineEdit::returnPressed, [urlBar, view]() {
        QString input = urlBar->text().trimmed();
        if (! input.contains(QStringLiteral("://"))) {
            input.prepend(QStringLiteral("https://"));
        }
        view->setUrl(QUrl::fromUserInput(input));
    });

    // Sync bar when the page navigates.
    QObject::connect(view, &QWebEngineView::urlChanged, [urlBar](const QUrl &url) {
        urlBar->setText(url.toDisplayString());
    });

    // Update window title from page.
    QObject::connect(page, &QWebEnginePage::titleChanged, [window](const QString &title) {
        window->setWindowTitle(title.isEmpty()
            ? QStringLiteral("Claude AI")
            : title + QStringLiteral(" — Claude AI"));
    });

    // Auto-grant notification permission when Claude requests it.
    QObject::connect(
        page,
        &QWebEnginePage::permissionRequested,
        [](QWebEnginePermission permission)
    {
        if (permission.permissionType() == QWebEnginePermission::PermissionType::Notifications) {
            permission.grant();
        }
    });

    // --- External link handling ---
    QObject::connect(
        page,
        &QWebEnginePage::navigationRequested,
        [](QWebEngineNavigationRequest &request)
    {
        const QUrl url = request.url();
        const QString host = url.host();

        if (host.contains(QStringLiteral("claude.ai"))
            || host.contains(QStringLiteral("anthropic.com"))
            || host.contains(QStringLiteral("clerk.accounts"))
            || host.contains(QStringLiteral("accounts.google.com"))
            || host.contains(QStringLiteral("appleid.apple.com"))
        ) {
            request.accept();
        } else if (! host.isEmpty()) {
            request.reject();
            QDesktopServices::openUrl(url);
        }
    });

    // Tooltip on hover.
    QObject::connect(
        page,
        &QWebEnginePage::linkHovered,
        [](const QString &url)
    {
        if (! url.isEmpty()) {
            QToolTip::showText(QCursor::pos(), url);
        } else {
            QToolTip::hideText();
        }
    });

    // --- System tray ---
    auto *tray = new KStatusNotifierItem(QStringLiteral("claude-ai"), &app);
    tray->setIconByName(QStringLiteral("claude-ai"));
    tray->setAttentionIconByName(QStringLiteral("claude-ai"));
    tray->setToolTip(
        QStringLiteral("claude-ai"),
        QStringLiteral("Claude AI"),
        QStringLiteral("AI Assistant")
    );
    tray->setCategory(KStatusNotifierItem::ApplicationStatus);
    tray->setStatus(KStatusNotifierItem::Active);
    tray->setStandardActionsEnabled(false);

    auto *toggleAction = new QAction(
        QIcon::fromTheme(QStringLiteral("view-preview")),
        QStringLiteral("Show/Hide"),
        window
    );
    toggleAction->setObjectName(QStringLiteral("toggleWindowAction"));

    auto *quitAction = new QAction(
        QIcon::fromTheme(QStringLiteral("application-exit")),
        QStringLiteral("Quit"),
        window
    );
    quitAction->setObjectName(QStringLiteral("quitAction"));

    auto *menu = new QMenu();
    menu->addAction(toggleAction);
    menu->addAction(quitAction);
    tray->setContextMenu(menu);

    // --- Toggle window logic ---
    // Context menu: straightforward visibility toggle.
    auto toggleVisibility = [window]() {
        if (window->isVisible()) {
            window->hide();
        } else {
            window->show();
            window->raise();
            window->activateWindow();
        }
    };

    // Tray left-click: raise if behind other windows, hide if focused.
    auto activateOrHide = [window]() {
        if (window->isVisible() && window->isActiveWindow()) {
            window->hide();
        } else {
            window->show();
            window->raise();
            window->activateWindow();
        }
    };

    QObject::connect(toggleAction, &QAction::triggered, toggleVisibility);
    QObject::connect(
        tray, &KStatusNotifierItem::activateRequested, activateOrHide
    );
    QObject::connect(quitAction, &QAction::triggered, &app, [window, &app]() {
        delete window; // Tear down WebEngine before profile/app destructor.
        app.quit();
    });

    // --- Global shortcut (Meta+Y) ---
    KGlobalAccel::self()->setGlobalShortcut(
        toggleAction,
        QKeySequence(QStringLiteral("Meta+Y"))
    );

    // --- Launch ---
    view->setUrl(QUrl(QStringLiteral("https://claude.ai/")));

    const bool startMinimized = app.arguments().contains(
        QStringLiteral("--background")
    );

    if (! startMinimized) {
        window->show();
    }

    return app.exec();
}
