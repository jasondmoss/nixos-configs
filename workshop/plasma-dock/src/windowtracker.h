#pragma once

#include <QObject>
#include <QHash>
#include <QSet>
#include <QDBusServiceWatcher>

class WindowTracker : public QObject
{
    Q_OBJECT

public:
    explicit WindowTracker(QObject *parent = nullptr);

    void watchDesktopId(const QString &desktopId);
    bool isRunning(const QString &desktopId) const;

Q_SIGNALS:
    void runningChanged(const QString &desktopId, bool running);
    void unknownAppStarted(const QString &desktopId);
    void unknownAppStopped(const QString &desktopId);

private Q_SLOTS:
    void onServiceRegistered(const QString &service);
    void onServiceUnregistered(const QString &service);
    void scanDBus();
    void scanProc();

private:
    void buildKSycocaMap();
    void loadBlocklist();
    QString desktopIdForService(const QString &service) const;

    // D-Bus tracking
    QDBusServiceWatcher     *m_watcher;
    QHash<QString, QString>  m_prefixToDesktopId;
    QSet<QString>            m_pinnedIds;
    QHash<QString, int>      m_serviceCount;

    // Proc tracking
    QHash<QString, QString>  m_execToDesktopId;

    // Running state
    QSet<QString>            m_running;
    QSet<QString>            m_dynamicRunning;

    // KConfig blocklists
    QSet<QString>            m_blocklist;      // never shown in dynamic section
    QSet<QString>            m_trayBlocklist;  // hidden when minimised to tray
};
