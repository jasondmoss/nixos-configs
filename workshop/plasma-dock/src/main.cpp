#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickWindow>

#include "layershellwindow.h"
#include "appmodel.h"
#include "iconprovider.h"
#include "dodgemanager.h"

int main(int argc, char *argv[])
{
    if (qgetenv("QT_QPA_PLATFORM").isEmpty())
        qputenv("QT_QPA_PLATFORM", "wayland");

    QGuiApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("plasma-dock"));
    app.setOrganizationName(QStringLiteral("workshop"));

    qmlRegisterType<LayerShellWindow>("org.kde.plasmadock", 1, 0, "LayerShellWindow");
    qmlRegisterType<AppModel>("org.kde.plasmadock", 1, 0, "AppModel");
    qmlRegisterType<DodgeManager>("org.kde.plasmadock", 1, 0, "DodgeManager");
    qmlRegisterUncreatableType<LayerShellWindow>(
        "org.kde.plasmadock", 1, 0, "DockEdge",
        QStringLiteral("DockEdge is an enum namespace"));

    QQmlApplicationEngine engine;
    engine.addImageProvider(QStringLiteral("icon"), new IconProvider);

    const QUrl mainQml(QStringLiteral("qrc:/qml/main.qml"));
    engine.load(mainQml);

    if (engine.rootObjects().isEmpty()) {
        qCritical() << "[PlasmaDock] Failed to load main.qml";
        return 1;
    }

    if (auto *w = qobject_cast<QQuickWindow *>(engine.rootObjects().first()))
        w->show();
    else
        qCritical() << "[PlasmaDock] Root object is not a QQuickWindow";

    return app.exec();
}
