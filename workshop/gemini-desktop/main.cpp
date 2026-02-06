#include <QApplication>
#include <QQmlApplicationEngine>
#include <QtWebEngineQuick/QtWebEngineQuick> // Essential for QML WebEngine
#include <KStatusNotifierItem>
#include <QUrl>

using namespace Qt::StringLiterals;

int main(int argc, char *argv[]) {
    // Initialize WebEngine BEFORE QApplication
    QtWebEngineQuick::initialize();

    QApplication app(argc, argv);
    app.setOrganizationName(u"MySystem"_s);
    app.setApplicationName(u"GeminiDesktop"_s);

    // Setup Persistence
    auto *profile = QWebEngineProfile::defaultProfile();
    profile->setPersistentStoragePath(app.applicationDirPath() + u"/storage"_s);
    profile->setPersistentCookiesPolicy(QWebEngineProfile::ForcePersistentCookies);

    // System Tray
    KStatusNotifierItem *trayItem = new KStatusNotifierItem(&app);
    trayItem->setIconByName(u"google-gemini"_s);
    trayItem->setCategory(KStatusNotifierItem::ApplicationStatus);
    trayItem->setStatus(KStatusNotifierItem::Active);

    QQmlApplicationEngine engine;
    const QUrl url(u"qrc:/main.qml"_s);

    // Safety check for QML loading
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed,
        &app, []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);

    engine.load(url);

    // Activation Logic
    QObject::connect(trayItem, &KStatusNotifierItem::activateRequested, [&]() {
        if (engine.rootObjects().isEmpty()) return;
        auto *window = qobject_cast<QWindow*>(engine.rootObjects().first());
        if (window) {
            if (window->isVisible()) {
                window->hide();
            } else {
                window->show();
                window->raise();
                window->requestActivate();
            }
        }
    });

    return app.exec();
}
