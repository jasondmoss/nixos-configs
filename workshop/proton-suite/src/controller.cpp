#include "controller.h"
#include <KGlobalAccel>
#include <KLocalizedString>
#include <QAction>
#include <QCoreApplication>
#include <QMenu>
#include <QtQuick>
// ADDED: Standard event headers
#include <QEvent>
#include <QCloseEvent>

Controller::Controller(QObject *parent)
    : QObject(parent), m_tray(nullptr), m_isVisible(true)
{
    setupTray();
    setupGlobalShortcut();
}

void Controller::setWindow(QQuickWindow* window)
{
    m_window = window;

    // CRITICAL FIX: We do NOT use connect() here anymore because
    // QQuickCloseEvent is incomplete in this Qt version. We use an event
    // filter instead.
    if (m_window) {
        m_window->installEventFilter(this);
    }
}

// CRITICAL FIX: Handle the close event via the standard QCloseEvent class
bool Controller::eventFilter(QObject *watched, QEvent *event)
{
    if (watched == m_window && event->type() == QEvent::Close) {
        auto *closeEvent = static_cast<QCloseEvent*>(event);
        closeEvent->ignore(); // Keep app running
        setVisible(false);    // Just hide the window

        return true;          // Event handled
    }

    return QObject::eventFilter(watched, event);
}

void Controller::setupTray()
{
    m_tray = new KStatusNotifierItem(this);
    m_tray->setTitle("Proton Suite");
    m_tray->setToolTip("Proton Suite", "Encrypted Workspace", "network-server-database");
    m_tray->setIconByName("proton-suite");
    m_tray->setCategory(KStatusNotifierItem::ApplicationStatus);
    m_tray->setStatus(KStatusNotifierItem::Active);

    m_tray->setStandardActionsEnabled(false);

    auto *menu = new QMenu();

    auto *toggleAction = menu->addAction(i18n("Show/Hide"));
    connect(toggleAction, &QAction::triggered, this, &Controller::toggleWindow);

    auto *quitAction = menu->addAction(i18n("Quit"));
    connect(quitAction, &QAction::triggered, this, &Controller::quit);

    m_tray->setContextMenu(menu);

    connect(
        m_tray,
        &KStatusNotifierItem::activateRequested,
        this,
        &Controller::toggleWindow
    );
}

void Controller::setupGlobalShortcut()
{
    QAction *action = new QAction(this);
    action->setText(i18n("Toggle Proton Suite"));
    action->setObjectName("ToggleWindow");

    KGlobalAccel::self()->setShortcut(
        action,
        {QKeySequence("Meta+X")},
        KGlobalAccel::Autoloading
    );
    connect(action, &QAction::triggered, this, &Controller::toggleWindow);
}

bool Controller::isVisible() const
{
    return m_isVisible;
}

void Controller::setVisible(bool visible)
{
    if (m_isVisible == visible) {
        return;
    }

    m_isVisible = visible;
    if (m_window) {
        if (visible) {
            m_window->show();
            m_window->raise();
            m_window->requestActivate();
        } else {
            m_window->hide();
        }
    }

    emit visibleChanged();
}

void Controller::toggleWindow()
{
    setVisible(!m_isVisible);
}

void Controller::activate()
{
    setVisible(true);
}

void Controller::quit()
{
    QCoreApplication::quit();
}
