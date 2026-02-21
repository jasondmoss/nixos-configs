#include "controller.h"
#include <KGlobalAccel>
#include <KLocalizedString>
#include <KNotification>
#include <QAction>
#include <QCoreApplication>
#include <QMenu>
#include <QtQuick>
#include <QEvent>
#include <QCloseEvent>

Controller::Controller(QObject *parent, bool startMinimized)
    : QObject(parent), m_tray(nullptr), m_isVisible(!startMinimized)
{
    setupTray();
    setupGlobalShortcut();
}

void Controller::setWindow(QQuickWindow *window)
{
    m_window = window;
    if (m_window) {
        m_window->installEventFilter(this);
    }
}

bool Controller::eventFilter(QObject *watched, QEvent *event)
{
    if (watched == m_window && event->type() == QEvent::Close) {
        auto *closeEvent = static_cast<QCloseEvent*>(event);
        closeEvent->ignore();
        setVisible(false);
        return true;
    }
    return QObject::eventFilter(watched, event);
}

void Controller::showNotification(const QString &title, const QString &message)
{
    KNotification *notify = new KNotification(
        QStringLiteral("event"),
        KNotification::CloseOnTimeout,
        this
    );
    notify->setTitle(title);
    notify->setText(message);
    notify->setIconName(QStringLiteral("proton-suite"));
    notify->sendEvent();
}

void Controller::setupTray()
{
    m_tray = new KStatusNotifierItem(this);
    m_tray->setTitle(QStringLiteral("Proton Suite"));
    m_tray->setToolTip(QStringLiteral("proton-suite"), QStringLiteral("Proton Suite"), QStringLiteral("Encrypted Workspace"));
    m_tray->setIconByName(QStringLiteral("proton-suite"));
    m_tray->setCategory(KStatusNotifierItem::ApplicationStatus);
    m_tray->setStatus(KStatusNotifierItem::Active);
    m_tray->setStandardActionsEnabled(false);

    auto *menu = new QMenu();

    auto *toggleAction = menu->addAction(i18n("Show/Hide"));
    connect(toggleAction, &QAction::triggered, this, &Controller::toggleWindow);

    auto *quitAction = menu->addAction(i18n("Quit"));
    connect(quitAction, &QAction::triggered, this, &Controller::quit);

    m_tray->setContextMenu(menu);
    connect(m_tray, &KStatusNotifierItem::activateRequested,
            this, &Controller::toggleWindow);
}

void Controller::setupGlobalShortcut()
{
    QAction *action = new QAction(this);
    action->setText(i18n("Toggle Proton Suite"));
    action->setObjectName(QStringLiteral("ToggleWindow"));

    KGlobalAccel::self()->setShortcut(
        action,
        {QKeySequence(QStringLiteral("Meta+X"))},
        KGlobalAccel::Autoloading
    );
    connect(action, &QAction::triggered, this, &Controller::toggleWindow);
}

bool Controller::isVisible() const { return m_isVisible; }

void Controller::setVisible(bool visible)
{
    if (m_isVisible == visible) return;

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

void Controller::toggleWindow() { setVisible(!m_isVisible); }
void Controller::activate()     { setVisible(true); }
void Controller::quit()         { QCoreApplication::quit(); }
