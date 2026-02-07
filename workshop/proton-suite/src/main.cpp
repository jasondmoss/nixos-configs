#include <QApplication>
#include <QQmlApplicationEngine>
#include <QtWebEngineQuick/QtWebEngineQuick>
#include <QQmlContext>
#include <KDBusService>
#include <KLocalizedString>
#include "controller.h"

#include <QStandardPaths>
#include <QDir>
#include <QDebug>

int main(int argc, char *argv[])
{
    QtWebEngineQuick::initialize();

    QApplication app(argc, argv);

    KLocalizedString::setApplicationDomain("proton-suite");

    // These names define the folder structure in ~/.local/share/
    app.setOrganizationName("Proton");
    app.setApplicationName("proton-suite");
    app.setWindowIcon(QIcon::fromTheme("proton-suite"));

    // Ensure the storage directory exists
    QString dataPath = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir dir(dataPath);

    if (! dir.exists()) {
        qInfo() << "Creating data directory:" << dataPath;
        dir.mkpath("."); // Effectively 'mkdir -p'
    } else {
        qInfo() << "Using data directory:" << dataPath;
    }

    KDBusService service(KDBusService::Unique);

    Controller controller;

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
        [url, &controller](QObject *obj,
        const QUrl &objUrl
    ) {
        if (!obj && url == objUrl) {
            QCoreApplication::exit(-1);
        }

        if (auto window = qobject_cast<QQuickWindow*>(obj)) {
            controller.setWindow(window);
        }
    }, Qt::QueuedConnection);

    engine.load(url);

    return app.exec();
}
