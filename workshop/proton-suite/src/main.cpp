#include <QApplication>
#include <QQmlApplicationEngine>
#include <QtWebEngineQuick/QtWebEngineQuick>
#include <QStandardPaths>
#include <QDir>
#include <QDebug>
#include <QIcon>
#include <QString>
#include <QMenu>
#include <QAction>
#include <QWindow>
#include <KStatusNotifierItem>

int main(int argc, char *argv[])
{
    QtWebEngineQuick::initialize();

    QApplication app(argc, argv);

    app.setQuitOnLastWindowClosed(false);
    app.setApplicationName(QStringLiteral("Proton Suite"));
    app.setOrganizationName(QStringLiteral("Proton"));
    app.setOrganizationDomain(QStringLiteral("nixos.local"));
    app.setWindowIcon(QIcon::fromTheme(QStringLiteral("proton-suite")));

    // 1. [NUCLEAR FIX] Manually Create the Storage Directory
    // QML fails if this folder doesn't exist yet.
    QString basePath = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    // Path: ~/.local/share/Proton/Proton Suite/QtWebEngine/ProtonSession
    QString storagePath = basePath + QStringLiteral("/QtWebEngine/ProtonSession");

    QDir dir(storagePath);
    if (!dir.exists()) {
        dir.mkpath(QStringLiteral("."));
        qDebug() << "Created storage directory:" << storagePath;
    }

    QQmlApplicationEngine engine;

    QObject::connect(
        &engine, &QQmlApplicationEngine::objectCreationFailed,
        &app, []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection
    );

    app.setWindowIcon(QIcon::fromTheme(QStringLiteral("proton-suite")));

    engine.load(QUrl(QStringLiteral("qrc:/qml/Main.qml")));

    // --- TRAY LOGIC ---
    KStatusNotifierItem *tray = new KStatusNotifierItem(&app);
    tray->setIconByName(QStringLiteral("proton-suite"));
    tray->setTitle(QStringLiteral("Proton Suite"));
    tray->setToolTip(QStringLiteral("Proton Suite"), QStringLiteral("Mail, Drive & Calendar"), QStringLiteral("proton-suite"));
    tray->setCategory(KStatusNotifierItem::ApplicationStatus);
    tray->setStatus(KStatusNotifierItem::Active);

    auto toggleWindow = [&engine]() {
        const auto rootObjects = engine.rootObjects();
        if (rootObjects.isEmpty()) return;
        QWindow *window = qobject_cast<QWindow*>(rootObjects.first());
        if (window) {
            if (window->isVisible()) {
                window->hide();
            } else {
                window->show();
                window->requestActivate();
            }
        }
    };

    QObject::connect(tray, &KStatusNotifierItem::activateRequested, &app, toggleWindow);

    QMenu *menu = tray->contextMenu();
    QAction *showAction = menu->addAction(QStringLiteral("Show/Hide"));
    QObject::connect(showAction, &QAction::triggered, &app, toggleWindow);

    QAction *quitAction = menu->addAction(QStringLiteral("Quit"));
    QObject::connect(quitAction, &QAction::triggered, &app, &QCoreApplication::quit);

    return app.exec();
}
