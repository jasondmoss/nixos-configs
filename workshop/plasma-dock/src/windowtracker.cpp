#include "windowtracker.h"

#include <QDBusConnection>
#include <QDBusInterface>
#include <QDBusReply>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QTimer>
#include <KService>
#include <KConfig>
#include <KConfigGroup>

static bool isSystemService(const QString &name)
{
    static const QStringList s_prefixes = {
        QStringLiteral("org.kde.KWin"),
        QStringLiteral("org.kde.plasma"),
        QStringLiteral("org.kde.kded"),
        QStringLiteral("org.kde.ksmserver"),
        QStringLiteral("org.kde.kglobalaccel"),
        QStringLiteral("org.kde.kwalletd"),
        QStringLiteral("org.kde.baloo"),
        QStringLiteral("org.kde.klipper"),
        QStringLiteral("org.kde.ActivityManager"),
        QStringLiteral("org.kde.StatusNotifier"),
        QStringLiteral("org.kde.ksecretd"),
        QStringLiteral("org.kde.secretservicecompat"),
        QStringLiteral("org.kde.kdeconnect"),
        QStringLiteral("org.kde.ScreenBrightness"),
        QStringLiteral("org.kde.screensaver"),
        QStringLiteral("org.kde.keyboard"),
        QStringLiteral("org.kde.touchpad"),
        QStringLiteral("org.kde.kuiserver"),
        QStringLiteral("org.kde.JobViewServer"),
        QStringLiteral("org.kde.kappmenu"),
        QStringLiteral("org.kde.GtkConfig"),
        QStringLiteral("org.kde.ksystemstats"),
        QStringLiteral("org.kde.kalendarac"),
        QStringLiteral("org.kde.runners"),
        QStringLiteral("org.kde.gmenudbusmenuproxy"),
        QStringLiteral("org.kde.xembedsniproxy"),
        QStringLiteral("org.kde.kaccess"),
        QStringLiteral("org.kde.Solid"),
        QStringLiteral("org.kde.org_kde_powerdevil"),
        QStringLiteral("org.kde.polkit"),
        QStringLiteral("org.kde.KWinWrapper"),
        QStringLiteral("org.kde.discover.notifier"),
    };
    for (const QString &prefix : s_prefixes)
        if (name.startsWith(prefix)) return true;
    return false;
}

// Returns true if the process has an open Unix socket connected to the
// Wayland compositor. Unix socket fds appear as "socket:[inode]" in
// /proc/PID/fd -- we resolve the Wayland socket inode from /proc/net/unix.
static bool hasWaylandConnection(const QString &pid)
{
    static const quint64 waylandInode = []() -> quint64 {
        const QString display = QString::fromLocal8Bit(qgetenv("WAYLAND_DISPLAY"));
        QString socketPath;
        if (display.startsWith(QLatin1Char('/'))) {
            socketPath = display;
        } else {
            const QString runtimeDir = QString::fromLocal8Bit(qgetenv("XDG_RUNTIME_DIR"));
            if (runtimeDir.isEmpty()) return 0;
            socketPath = runtimeDir + QLatin1Char('/') + display;
        }

        QFile netUnix(QStringLiteral("/proc/net/unix"));
        if (!netUnix.open(QIODevice::ReadOnly | QIODevice::Text)) return 0;

        while (!netUnix.atEnd()) {
            const QString line = QString::fromLocal8Bit(netUnix.readLine()).trimmed();
            if (!line.endsWith(socketPath)) continue;
            const QStringList cols = line.split(QLatin1Char(' '), Qt::SkipEmptyParts);
            if (cols.size() >= 7) {
                bool ok;
                const quint64 inode = cols[6].toULongLong(&ok);
                if (ok && inode > 0) return inode;
            }
        }
        return 0;
    }();

    if (waylandInode == 0) return true;

    const QString socketEntry = QStringLiteral("socket:[%1]").arg(waylandInode);
    const QDir fdDir(QStringLiteral("/proc/") + pid + QStringLiteral("/fd"));
    const auto entries = fdDir.entryList(QDir::Files | QDir::System | QDir::NoDotAndDotDot);
    for (const QString &entry : entries) {
        const QString target = QFile::symLinkTarget(fdDir.filePath(entry));
        if (target == socketEntry)
            return true;
    }
    return false;
}

// ─────────────────────────────────────────────────────────────────────────────
WindowTracker::WindowTracker(QObject *parent)
    : QObject(parent)
    , m_watcher(new QDBusServiceWatcher(this))
{
    m_watcher->setConnection(QDBusConnection::sessionBus());
    m_watcher->setWatchMode(
        QDBusServiceWatcher::WatchForRegistration |
        QDBusServiceWatcher::WatchForUnregistration);
    m_watcher->addWatchedService(QStringLiteral("org.kde.*"));

    connect(m_watcher, &QDBusServiceWatcher::serviceRegistered,
            this,      &WindowTracker::onServiceRegistered);
    connect(m_watcher, &QDBusServiceWatcher::serviceUnregistered,
            this,      &WindowTracker::onServiceUnregistered);

    buildKSycocaMap();
    loadBlocklist();

    // D-Bus scan every 2s
    QTimer *dbusTimer = new QTimer(this);
    dbusTimer->setInterval(2000);
    connect(dbusTimer, &QTimer::timeout, this, &WindowTracker::scanDBus);
    dbusTimer->start();

    // /proc scan every 2s, staggered by 1s from dbus scan
    QTimer *procTimer = new QTimer(this);
    procTimer->setInterval(2000);
    connect(procTimer, &QTimer::timeout, this, &WindowTracker::scanProc);
    QTimer::singleShot(1000, procTimer, [procTimer]{ procTimer->start(); });


}

void WindowTracker::watchDesktopId(const QString &desktopId)
{
    if (desktopId.isEmpty()) return;
    m_prefixToDesktopId.insert(desktopId, desktopId);
    m_pinnedIds.insert(desktopId);
}

bool WindowTracker::isRunning(const QString &desktopId) const
{
    return m_running.contains(desktopId);
}

// ─────────────────────────────────────────────────────────────────────────────
// Tray filtering
// ─────────────────────────────────────────────────────────────────────────────



// ─────────────────────────────────────────────────────────────────────────────
// D-Bus watcher callbacks
// ─────────────────────────────────────────────────────────────────────────────
void WindowTracker::onServiceRegistered(const QString &service)
{
    if (!service.startsWith(QLatin1String("org.kde."))) return;
    if (isSystemService(service)) return;

    const QString id = desktopIdForService(service);
    if (id.isEmpty()) return;

    m_serviceCount[id]++;
    if (!m_running.contains(id)) {
        m_running.insert(id);
        if (m_pinnedIds.contains(id)) {
            Q_EMIT runningChanged(id, true);
        } else {
            m_dynamicRunning.insert(id);
            Q_EMIT unknownAppStarted(id);
        }
    }
}

void WindowTracker::onServiceUnregistered(const QString &service)
{
    if (!service.startsWith(QLatin1String("org.kde."))) return;

    const QString id = desktopIdForService(service);
    if (id.isEmpty()) return;

    m_serviceCount[id] = qMax(0, m_serviceCount.value(id, 0) - 1);
    if (m_serviceCount[id] == 0 && m_running.contains(id)) {
        m_running.remove(id);
        if (m_pinnedIds.contains(id)) {
            Q_EMIT runningChanged(id, false);
        } else if (m_dynamicRunning.remove(id)) {
            Q_EMIT unknownAppStopped(id);
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// D-Bus periodic scan
// ─────────────────────────────────────────────────────────────────────────────
void WindowTracker::scanDBus()
{
    QDBusInterface dbus(
        QStringLiteral("org.freedesktop.DBus"),
        QStringLiteral("/org/freedesktop/DBus"),
        QStringLiteral("org.freedesktop.DBus"),
        QDBusConnection::sessionBus());

    QDBusReply<QStringList> reply = dbus.call(QStringLiteral("ListNames"));
    if (!reply.isValid()) return;

    QSet<QString> active;
    for (const QString &name : reply.value()) {
        if (!name.startsWith(QLatin1String("org.kde."))) continue;
        if (isSystemService(name)) continue;
        const QString id = desktopIdForService(name);
        if (!id.isEmpty()) active.insert(id);
    }

    for (const QString &id : std::as_const(m_pinnedIds)) {
        const bool now = active.contains(id);
        const bool was = m_running.contains(id);
        if (now && !was) {
            m_running.insert(id); m_serviceCount[id] = 1;
            Q_EMIT runningChanged(id, true);
        } else if (!now && was && !m_dynamicRunning.contains(id)) {
            m_running.remove(id); m_serviceCount[id] = 0;
            Q_EMIT runningChanged(id, false);
        }
    }

    for (const QString &id : std::as_const(active)) {
        if (m_pinnedIds.contains(id)) continue;
        if (!m_dynamicRunning.contains(id)) {
            m_running.insert(id);
            m_dynamicRunning.insert(id);
            m_serviceCount[id] = 1;
            Q_EMIT unknownAppStarted(id);
        }
    }

    const QSet<QString> gone = m_dynamicRunning - active;
    for (const QString &id : gone) {
        if (!id.startsWith(QLatin1String("org.kde."))) continue;
        m_running.remove(id);
        m_dynamicRunning.remove(id);
        m_serviceCount[id] = 0;
        Q_EMIT unknownAppStopped(id);
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// /proc scan
// ─────────────────────────────────────────────────────────────────────────────
void WindowTracker::scanProc()
{
    QSet<QString> activeDesktopIds;
    // Track which desktop ID came from which PID, for tray filtering
    QHash<QString, QString> desktopIdToPid;

    const QDir proc(QStringLiteral("/proc"));
    const auto pids = proc.entryList(QDir::Dirs | QDir::NoDotAndDotDot);

    for (const QString &pid : pids) {
        bool ok;
        pid.toInt(&ok);
        if (!ok) continue;

        if (!hasWaylandConnection(pid)) continue;

        QStringList candidates;

        const QString exePath = QFile::symLinkTarget(
            QStringLiteral("/proc/") + pid + QStringLiteral("/exe"));
        if (!exePath.isEmpty()) {
            QString base = QFileInfo(exePath).fileName();
            if (base.endsWith(QLatin1String(".wrapped"))) base.chop(8);
            if (base.startsWith(QLatin1Char('.'))) base = base.mid(1);
            if (!base.isEmpty()) candidates << base;
        }

        QFile cmdlineFile(QStringLiteral("/proc/") + pid + QStringLiteral("/cmdline"));
        if (cmdlineFile.open(QIODevice::ReadOnly)) {
            const QByteArray data = cmdlineFile.read(512);
            cmdlineFile.close();
            const int nullPos = data.indexOf('\0');
            const QByteArray argv0 = nullPos > 0 ? data.left(nullPos) : data;
            QString base = QFileInfo(QString::fromLocal8Bit(argv0)).fileName();
            if (base.endsWith(QLatin1String(".wrapped"))) base.chop(8);
            if (base.startsWith(QLatin1Char('.'))) base = base.mid(1);
            if (!base.isEmpty() && !candidates.contains(base))
                candidates << base;

            // NixOS parent dir name (e.g. .../firefox-nightly/firefox)
            const QString parentDir = QFileInfo(QString::fromLocal8Bit(argv0)).dir().dirName();
            if (!parentDir.isEmpty() && !candidates.contains(parentDir))
                candidates << parentDir;
        }

        bool matched = false;
        for (const QString &execBase : std::as_const(candidates)) {
            if (m_execToDesktopId.contains(execBase)) {
                const QString desktopId = m_execToDesktopId[execBase];
                activeDesktopIds.insert(desktopId);
                desktopIdToPid.insert(desktopId, pid);
                matched = true;
                break;
            }
            for (auto it = m_execToDesktopId.constBegin();
                 it != m_execToDesktopId.constEnd(); ++it) {
                if (execBase.startsWith(it.key())) {
                    activeDesktopIds.insert(it.value());
                    desktopIdToPid.insert(it.value(), pid);
                    matched = true;
                    break;
                }
            }
            if (matched) break;
        }
    }

    // Apply blocklist (never shown)
    for (const QString &blocked : std::as_const(m_blocklist))
        activeDesktopIds.remove(blocked);

    // Apply tray blocklist (hidden when tray-only — no visible window).
    // Since KWin 6 exposes no window enumeration API, this is user-configured.
    for (const QString &blocked : std::as_const(m_trayBlocklist))
        activeDesktopIds.remove(blocked);

    // Appeared
    for (const QString &id : std::as_const(activeDesktopIds)) {
        if (m_pinnedIds.contains(id)) {
            if (!m_running.contains(id)) {
                m_running.insert(id);
                Q_EMIT runningChanged(id, true);
            }
        } else if (!m_dynamicRunning.contains(id)) {
            m_running.insert(id);
            m_dynamicRunning.insert(id);
            Q_EMIT unknownAppStarted(id);
        }
    }

    // Disappeared (non-KDE only)
    const QSet<QString> procDynamic = m_dynamicRunning - m_pinnedIds;
    for (const QString &id : procDynamic) {
        if (id.startsWith(QLatin1String("org.kde."))) continue;
        if (!activeDesktopIds.contains(id)) {
            m_running.remove(id);
            m_dynamicRunning.remove(id);
            Q_EMIT unknownAppStopped(id);
        }
    }

    for (const QString &id : std::as_const(m_pinnedIds)) {
        if (id.startsWith(QLatin1String("org.kde."))) continue;
        if (m_running.contains(id) && !activeDesktopIds.contains(id)) {
            m_running.remove(id);
            Q_EMIT runningChanged(id, false);
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// KSycoca exec map
// ─────────────────────────────────────────────────────────────────────────────
void WindowTracker::buildKSycocaMap()
{
    const auto services = KService::allServices();
    for (const KService::Ptr &svc : services) {
        if (!svc->isApplication() || svc->noDisplay()) continue;

        QString exec = svc->exec();
        if (exec.isEmpty()) continue;

        const int space = exec.indexOf(QLatin1Char(' '));
        if (space > 0) exec = exec.left(space);

        const int slash = exec.lastIndexOf(QLatin1Char('/'));
        if (slash >= 0) exec = exec.mid(slash + 1);

        if (exec.startsWith(QLatin1Char('%'))) continue;

        if (!exec.isEmpty())
            m_execToDesktopId.insert(exec, svc->desktopEntryName());
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// KConfig blocklist
// Stored in ~/.config/plasma-dockrc under [DynamicApps] blocklist=...
// Default: conky, fcitx5
// ─────────────────────────────────────────────────────────────────────────────
void WindowTracker::loadBlocklist()
{
    KConfig config(QStringLiteral("plasma-dockrc"));
    KConfigGroup grp = config.group(QStringLiteral("DynamicApps"));

    // Dynamic section blocklist — apps never shown (background processes, widgets)
    const QStringList blockDefaults = {
        QStringLiteral("conky"),
        QStringLiteral("org.fcitx.Fcitx5"),
    };
    if (!grp.hasKey("blocklist"))
        grp.writeEntry("blocklist", blockDefaults);
    const QStringList blockList = grp.readEntry("blocklist", blockDefaults);
    m_blocklist = QSet<QString>(blockList.begin(), blockList.end());

    // Tray blocklist — apps hidden when minimised to tray (no visible window).
    // KWin 6 exposes no window enumeration API over D-Bus so we rely on the
    // user explicitly listing apps that live in the system tray.
    const QStringList trayDefaults = {
        QStringLiteral("1password"),
        QStringLiteral("io.github.nuttyartist.notes"),
    };
    if (!grp.hasKey("tray_blocklist"))
        grp.writeEntry("tray_blocklist", trayDefaults);
    const QStringList trayList = grp.readEntry("tray_blocklist", trayDefaults);
    m_trayBlocklist = QSet<QString>(trayList.begin(), trayList.end());
}

QString WindowTracker::desktopIdForService(const QString &service) const
{
    if (m_prefixToDesktopId.contains(service))
        return m_prefixToDesktopId[service];

    const int dash = service.lastIndexOf(QLatin1Char('-'));
    if (dash > 0) {
        const QString prefix = service.left(dash);
        if (m_prefixToDesktopId.contains(prefix))
            return m_prefixToDesktopId[prefix];
        if (prefix.startsWith(QLatin1String("org.kde.")) && !isSystemService(prefix))
            return prefix;
    }

    if (service.startsWith(QLatin1String("org.kde.")) && !isSystemService(service))
        return service;

    return {};
}
