#include <QApplication>
#include <QWebEngineView>
#include <QWebEngineProfile>
#include <QWebEnginePage>
#include <QWebEngineSettings>
#include <QWebEngineNavigationRequest>
#include <KStatusNotifierItem>
#include <KGlobalAccel>
#include <QAction>
#include <QMenu>
#include <QIcon>
#include <QStandardPaths>
#include <QStringLiteral>
#include <QUrl>
#include <QDir>
#include <QDesktopServices>
#include <QToolTip>

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("feedbin-rss"));
    app.setWindowIcon(QIcon::fromTheme(QStringLiteral("feedbin-rss")));

    // --- Persistence Setup ---
    const QString appDataPath = QStandardPaths::writableLocation(
        QStandardPaths::AppDataLocation
    );
    const QString storagePath = appDataPath + QStringLiteral("/webengine");
    QDir().mkpath(storagePath);

    // Create profile first, parented to app to ensure it outlives the view
    auto *profile = new QWebEngineProfile(QStringLiteral("feedbin-storage"), &app);
    profile->setPersistentStoragePath(storagePath);
    profile->setPersistentCookiesPolicy(QWebEngineProfile::ForcePersistentCookies);

    auto *view = new QWebEngineView();
    auto *page = new QWebEnginePage(profile, view); // Page parented to View
    view->setPage(page);

    view->setWindowTitle(QStringLiteral("Feedbin RSS"));
    view->resize(1700, 1200);

    // Listener for Tooltips.
    QObject::connect(page, &QWebEnginePage::linkHovered, [](const QString &url) {
        if (! url.isEmpty()) {
            // Show the URL as a tooltip at the current mouse position.
            QToolTip::showText(QCursor::pos(), url);
        } else {
            // Hide the tooltip when moving away from a link.
            QToolTip::hideText();
        }
    });

    // --- External Link Handling (C++ Side) ---
    QObject::connect(
        page,
        &QWebEnginePage::navigationRequested,
        [](QWebEngineNavigationRequest &request)
    {
        const QUrl url = request.url();
        if (! url.host().contains(QStringLiteral("feedbin.com"))
            && !url.host().isEmpty()
        ) {
            request.reject();
            QDesktopServices::openUrl(url);
        } else {
            request.accept();
        }
    });

    // This catches links that Feedbin tries to open via JS or target="_blank"
    QObject::connect(page, &QWebEnginePage::loadFinished, [page](bool ok) {
        if (ok) {
            page->runJavaScript(QStringLiteral(
                "document.addEventListener('click', (e) => {"
                "    let anchor = e.target.closest('a');"
                "    if (anchor && anchor.href && ! anchor.href.includes('feedbin.com')) {"
                "        e.preventDefault();"
                "        window.location.href = anchor.href;"
                "    }"
                "}, true);"

                // HOVER Handler (Targeted Tooltips)
                "document.addEventListener('mouseover', (e) => {"
                "    let anchor = e.target.closest('a');"
                "    /* Only show tooltip if link is inside the article content column */"
                "    if (anchor && anchor.closest('.entry-column.has-content .entry-inner')) {"
                "        window.status = 'hover:' + anchor.href;"
                "    } else {"
                "        window.status = '';"
                "    }"
                "}, true);"

                // MOUSEOUT Handler (Cleanup)
                "document.addEventListener('mouseout', (e) => {"
                "    window.status = '';"
                "}, true);"
            ));
        }
    });

    view->settings()->setAttribute(QWebEngineSettings::LocalStorageEnabled, true);
    view->setUrl(QUrl(QStringLiteral("https://feedbin.com/")));

    // --- Tray & Actions ---
    auto *tray = new KStatusNotifierItem(QStringLiteral("feedbin-rss"), &app);
    tray->setObjectName(QStringLiteral("feedbinTray"));
    tray->setIconByName(QStringLiteral("feedbin-rss"));
    tray->setAttentionIconByName(QStringLiteral("feedbin-rss"));
    tray->setCategory(KStatusNotifierItem::ApplicationStatus);
    tray->setStatus(KStatusNotifierItem::Active);
    tray->setStandardActionsEnabled(false);

    auto *toggleAction = new QAction(
        QIcon::fromTheme(QStringLiteral("view-preview")),
        QStringLiteral("Show/Hide"),
        view
    );
    toggleAction->setObjectName(QStringLiteral("toggleWindowAction"));

    auto *quitAction = new QAction(
        QIcon::fromTheme(QStringLiteral("application-exit")),
        QStringLiteral("Quit"),
        view
    );
    quitAction->setObjectName(QStringLiteral("quitAction"));

    auto *menu = new QMenu();
    menu->addAction(toggleAction);
    menu->addAction(quitAction);
    tray->setContextMenu(menu);

    // --- Shortcuts & Signals ---
    auto toggleWindow = [view]() {
        if (view->isVisible() && view->isActiveWindow()) view->hide();
        else { view->show(); view->raise(); view->activateWindow(); }
    };

    QObject::connect(toggleAction, &QAction::triggered, toggleWindow);
    QObject::connect(tray, &KStatusNotifierItem::activateRequested, toggleWindow);
    QObject::connect(quitAction, &QAction::triggered, &app, &QApplication::quit);

    KGlobalAccel::self()->setGlobalShortcut(
        toggleAction,
        QKeySequence(QStringLiteral("Meta+S"))
    );

    app.setQuitOnLastWindowClosed(false);

    // Check if the "--background" flag was passed.
    bool startMinimized = app.arguments().contains(QStringLiteral("--background"));
    if (! startMinimized) {
        view->show();
    } else {
        // Ensure the window is technically created but not visible.
        view->hide();
    }

    return app.exec();
}
