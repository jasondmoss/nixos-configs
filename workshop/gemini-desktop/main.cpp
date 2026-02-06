#include <QApplication>
#include <QQmlApplicationEngine>
#include <QtWebEngineQuick/QtWebEngineQuick>
#include <QWebEngineProfile>
#include <KStatusNotifierItem>
#include <KGlobalAccel>
#include <QMenu>
#include <QAction>
#include <QStandardPaths>
#include <QDir>
#include <QUrl>
#include <QQuickWindow>
#include <QTimer>

using namespace Qt::StringLiterals;

int main(int argc, char *argv[]) {
    // Force OpenGL for NVIDIA stability.
    QQuickWindow::setGraphicsApi(QSGRendererInterface::OpenGL);

    // Initialize Engine.
    QtWebEngineQuick::initialize();

    QApplication app(argc, argv);
    app.setOrganizationName(u"Google"_s);
    app.setApplicationName(u"GeminiDesktop"_s);
    app.setQuitOnLastWindowClosed(false);

    // Create the Persistence Layer.
    // We create the profile in C++ to ensure paths are created before QML loads.
    QWebEngineProfile *profile = new QWebEngineProfile(u"GeminiShared"_s, &app);

    QString dataPath = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QString storagePath = dataPath + u"/SharedData"_s;
    QDir().mkpath(storagePath);

    profile->setPersistentStoragePath(storagePath);
    profile->setPersistentCookiesPolicy(QWebEngineProfile::ForcePersistentCookies);
    profile->setHttpCacheType(QWebEngineProfile::DiskHttpCache);

    QQmlApplicationEngine engine;
    const QUrl url(u"qrc:/main.qml"_s);

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection
    );

    engine.load(url);

    // System Tray Integration.
    KStatusNotifierItem *trayItem = new KStatusNotifierItem(&app);
    trayItem->setIconByName(u"google-gemini"_s);
    trayItem->setStatus(KStatusNotifierItem::Active);
    trayItem->setToolTip(u"google-gemini"_s, u"Gemini"_s, u"AI Assistant"_s);

    QMenu *trayMenu = new QMenu();
    QAction *quitAction = trayMenu->addAction(u"Quit Gemini"_s);

    // Graceful Shutdown (Prevent Data Corruption).
    // We wait 1.5s after hiding to allow the Chromium thread to flush to disk.
    QObject::connect(quitAction, &QAction::triggered, [&]() {
        for (auto *win : app.topLevelWindows()) {
            win->hide();
        }

        QTimer::singleShot(1500, [&]() {
            app.quit();
        });
    });

    trayItem->setContextMenu(trayMenu);

    // Global Shortcut (Meta+Z) & Tray Click Logic.
    QAction *toggleAction = new QAction(u"Toggle Gemini"_s, &app);
    toggleAction->setObjectName(u"ToggleWindow"_s);

    KGlobalAccel::self()->setShortcut(toggleAction, {QKeySequence(u"Meta+Z"_s)});

    auto toggleWindow = [&]() {
        if (engine.rootObjects().isEmpty()) {
            return;
        }

        auto *window = qobject_cast<QWindow*>(engine.rootObjects().first());

        if (window) {
            if (window->isVisible() && window->isActive()) {
                window->hide();
            } else {
                window->show();
                window->raise();
                window->requestActivate();
            }
        }
    };

    QObject::connect(toggleAction, &QAction::triggered, toggleWindow);
    QObject::connect(trayItem, &KStatusNotifierItem::activateRequested, toggleWindow);

    return app.exec();
}
