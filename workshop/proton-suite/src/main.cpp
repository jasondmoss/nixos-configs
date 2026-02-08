#include <QApplication>
#include <QQmlApplicationEngine>
#include <QtWebEngineQuick/QtWebEngineQuick>
#include <QWebEngineProfile>
#include <QWebEngineNotification>
#include <QQmlContext>
#include <KDBusService>
#include <KLocalizedString>
#include <KNotification>
#include "controller.h"

#include <QStandardPaths>
#include <QDir>
#include <QDebug>

int main(int argc, char *argv[]) {
    QtWebEngineQuick::initialize();

    QApplication app(argc, argv);
    KLocalizedString::setApplicationDomain("proton-suite");
    app.setOrganizationName("Proton");
    app.setApplicationName("proton-suite");
    app.setWindowIcon(QIcon::fromTheme("proton-suite"));

    QCommandLineParser parser;
    parser.setApplicationDescription("Proton Suite PWA");
    parser.addHelpOption();
    parser.addVersionOption();

    // Define the --background option
    QCommandLineOption minOption(
        "background",
        "Start application minimized to system tray."
    );
    parser.addOption(minOption);
    parser.process(app);

    bool startMinimized = parser.isSet(minOption);

    // Data Path.
    QString dataPath = QStandardPaths::writableLocation(
        QStandardPaths::AppDataLocation
    );
    QDir dir(dataPath);
    if (! dir.exists()) {
        dir.mkpath(".");
    }

    // Master Profile.
    QWebEngineProfile *profile = new QWebEngineProfile("proton", &app);
    profile->setPersistentStoragePath(dataPath + "/proton");
    profile->setPersistentCookiesPolicy(QWebEngineProfile::ForcePersistentCookies);
    profile->setHttpCacheType(QWebEngineProfile::DiskHttpCache);

    // Notification Bridge.
    profile->setNotificationPresenter(
        [](std::unique_ptr<QWebEngineNotification> webNotice
    ) {
        KNotification *notify = new KNotification("event");
        notify->setTitle(webNotice->title());
        notify->setText(webNotice->message());
        notify->setIconName("proton-suite");
        notify->sendEvent();
    });

    KDBusService service(KDBusService::Unique);
    Controller controller(nullptr, startMinimized);
    QObject::connect(
        &service,
        &KDBusService::activateRequested,
        &controller,
        &Controller::activate
    );

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("Controller", &controller);

    const QUrl url(QStringLiteral("qrc:/ProtonSuite/src/qml/Main.qml"));
    QObject::connect(
            &engine,
            &QQmlApplicationEngine::objectCreated,
            &app,
            [url, &controller](QObject *obj, const QUrl &objUrl)
        {
                if (! obj && url == objUrl) {
                    QCoreApplication::exit(-1);
                }

                if (auto window = qobject_cast<QQuickWindow*>(obj)) {
                    controller.setWindow(window);
                }
        }, Qt::QueuedConnection
    );

    engine.load(url);

    return app.exec();
}
