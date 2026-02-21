#include <QApplication>
#include <QQmlApplicationEngine>
#include <QtWebEngineQuick/QtWebEngineQuick>
#include <QQmlContext>
#include <KDBusService>
#include <KLocalizedString>
#include "controller.h"

int main(int argc, char *argv[]) {
    QtWebEngineQuick::initialize();

    QApplication app(argc, argv);
    KLocalizedString::setApplicationDomain("proton-suite");
    app.setOrganizationName(QStringLiteral("Proton"));
    app.setApplicationName(QStringLiteral("proton-suite"));
    app.setWindowIcon(QIcon::fromTheme(QStringLiteral("proton-suite")));

    QCommandLineParser parser;
    parser.setApplicationDescription(QStringLiteral("Proton Suite PWA"));
    parser.addHelpOption();
    parser.addVersionOption();

    QCommandLineOption minOption(
        QStringLiteral("background"),
        QStringLiteral("Start application minimized to system tray.")
    );
    parser.addOption(minOption);
    parser.process(app);

    Controller controller(nullptr, parser.isSet(minOption));

    KDBusService service(KDBusService::Unique);
    QObject::connect(
        &service,
        &KDBusService::activateRequested,
        &controller,
        &Controller::activate
    );

    QQmlApplicationEngine engine;
    engine.rootContext()
        ->setContextProperty(QStringLiteral("Controller"), &controller);

    const QUrl url(QStringLiteral("qrc:/ProtonSuite/src/qml/Main.qml"));
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreated,
        &app,
        [url, &controller](QObject *obj, const QUrl &objUrl) {
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
