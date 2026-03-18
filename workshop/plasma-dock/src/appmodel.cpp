#include "appmodel.h"
#include "windowtracker.h"

#include <QProcess>
#include <QProcessEnvironment>
#include <QRegularExpression>
#include <KService>
#include <KConfig>
#include <KConfigGroup>
#include <QDBusInterface>
#include <QDBusReply>
#include <QDateTime>
#include <QFile>
#include <QTimer>

static const QStringList s_defaultApps = {
    QStringLiteral("org.kde.dolphin"),
    QStringLiteral("org.kde.konsole"),
    QStringLiteral("org.kde.kate"),
    QStringLiteral("firefox-nightly"),
    QStringLiteral("org.kde.discover"),
    QStringLiteral("systemsettings"),
};

AppModel::AppModel(QObject *parent)
    : QAbstractListModel(parent)
{
    loadPinned();

    m_tracker = new WindowTracker(this);
    connect(m_tracker, &WindowTracker::runningChanged,
            this,      &AppModel::onRunningChanged);
    connect(m_tracker, &WindowTracker::unknownAppStarted,
            this,      &AppModel::onUnknownAppStarted);
    connect(m_tracker, &WindowTracker::unknownAppStopped,
            this,      &AppModel::onUnknownAppStopped);

    for (const AppEntry &e : std::as_const(m_entries))
        m_tracker->watchDesktopId(e.desktopId);
}

int AppModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid()) return 0;
    return m_entries.size();
}

QVariant AppModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_entries.size())
        return {};

    const AppEntry &e = m_entries.at(index.row());
    switch (role) {
    case DesktopIdRole:   return e.desktopId;
    case NameRole:        return e.name;
    case IconNameRole:    return e.iconName;
    case ExecRole:        return e.exec;
    case RunningRole:     return m_tracker ? m_tracker->isRunning(e.desktopId) : false;
    case IsSeparatorRole: return e.isSeparator;
    case IsPinnedRole:    return e.pinned;
    case Qt::DisplayRole: return e.name;
    default: return {};
    }
}

QHash<int, QByteArray> AppModel::roleNames() const
{
    return {
        { DesktopIdRole,   "desktopId"   },
        { NameRole,        "name"        },
        { IconNameRole,    "iconName"    },
        { ExecRole,        "exec"        },
        { RunningRole,     "isRunning"   },
        { IsSeparatorRole, "isSeparator" },
        { IsPinnedRole,    "isPinned"    },
    };
}

void AppModel::launch(int index) const
{
    if (index < 0 || index >= m_entries.size()) return;
    const AppEntry &e = m_entries.at(index);
    if (e.isSeparator || e.exec.isEmpty()) return;

    QString cmd = e.exec;
    cmd.remove(QRegularExpression(QStringLiteral("%[a-zA-Z]")));
    cmd = cmd.trimmed();


    QProcess proc;
    QProcessEnvironment env = QProcessEnvironment::systemEnvironment();
    env.remove(QStringLiteral("QT_WAYLAND_SHELL_INTEGRATION"));
    env.remove(QStringLiteral("QML_DISABLE_DISK_CACHE"));
    proc.setProcessEnvironment(env);
    proc.setProgram(QStringLiteral("/bin/sh"));
    proc.setArguments({ QStringLiteral("-c"), cmd });
    proc.startDetached();
}

void AppModel::moveApp(int from, int to)
{
    if (from == to
     || from < 0 || from >= m_entries.size()
     || to   < 0 || to   >= m_entries.size()) return;
    if (m_entries.at(from).isSeparator || m_entries.at(to).isSeparator) return;
    // Only allow reordering within the pinned section
    if (!m_entries.at(from).pinned || !m_entries.at(to).pinned) return;

    const int dest = (to > from) ? to + 1 : to;
    beginMoveRows({}, from, from, {}, dest);
    m_entries.move(from, to);
    endMoveRows();
    savePinned();
}

// Promote a dynamic entry to pinned, inserting before the separator.
void AppModel::pinApp(const QString &desktopId)
{
    // Find dynamic entry
    int dynIdx = -1;
    for (int i = 0; i < m_entries.size(); ++i) {
        if (!m_entries.at(i).pinned && m_entries.at(i).desktopId == desktopId) {
            dynIdx = i;
            break;
        }
    }
    if (dynIdx < 0) return;

    AppEntry e = m_entries.at(dynIdx);
    e.pinned = true;

    // Remove from dynamic section
    beginRemoveRows({}, dynIdx, dynIdx);
    m_entries.removeAt(dynIdx);
    endRemoveRows();

    // Insert before separator (end of pinned section)
    int insertAt = separatorRow();
    if (insertAt < 0) insertAt = m_entries.size();

    beginInsertRows({}, insertAt, insertAt);
    m_entries.insert(insertAt, e);
    endInsertRows();

    m_pinnedIds.insert(desktopId);
    m_tracker->watchDesktopId(desktopId);
    Q_EMIT countChanged();

    // Remove separator if dynamic section is now empty
    bool hasDynamic = false;
    for (const AppEntry &entry : m_entries)
        if (!entry.pinned && !entry.isSeparator) { hasDynamic = true; break; }
    if (!hasDynamic) {
        const int sep = separatorRow();
        if (sep >= 0) {
            beginRemoveRows({}, sep, sep);
            m_entries.removeAt(sep);
            endRemoveRows();
            Q_EMIT countChanged();
        }
    }

    savePinned();
}

// Demote a pinned entry. If the app is running it moves to the dynamic section;
// if not running it is removed from the dock entirely.
void AppModel::unpinApp(int idx)
{
    if (idx < 0 || idx >= m_entries.size()) return;
    if (!m_entries.at(idx).pinned) return;

    AppEntry e = m_entries.at(idx);
    const bool running = m_tracker && m_tracker->isRunning(e.desktopId);

    beginRemoveRows({}, idx, idx);
    m_entries.removeAt(idx);
    endRemoveRows();
    m_pinnedIds.remove(e.desktopId);
    Q_EMIT countChanged();

    if (running) {
        // Keep visible as a dynamic entry
        e.pinned = false;
        addDynamicEntry(e.desktopId);
    }

    savePinned();
}

// Raise or minimise a running app via a one-shot KWin JS script, or launch
// it if it is not running. Uses KWin's D-Bus scripting interface which is
// available on all KDE Plasma 6 installations without additional dependencies.
void AppModel::activateOrLaunch(int index)
{
    if (index < 0 || index >= m_entries.size()) return;
    const AppEntry &e = m_entries.at(index);
    if (e.isSeparator) return;

    if (!m_tracker || !m_tracker->isRunning(e.desktopId)) {
        launch(index);
        return;
    }

    // Derive the resource class KWin will report for this app.
    // KWin sets resourceClass from the app_id (Wayland) or WM_CLASS (X11).
    // For reverse-DNS desktop IDs ("org.kde.konsole") the class is the last
    // component. For flat IDs ("firefox-nightly") it is the ID itself.
    const QString resourceClass = e.desktopId.contains(QLatin1Char('.'))
        ? e.desktopId.section(QLatin1Char('.'), -1).toLower()
        : e.desktopId.toLower();

    // Timestamp-based name ensures KWin never returns a cached script object.
    const QString name = QStringLiteral("plasma-dock-raise-%1")
        .arg(QDateTime::currentMSecsSinceEpoch());
    const QString path = QStringLiteral("/tmp/%1.js").arg(name);


    // Raw string literal avoids newline-in-string-literal compiler errors.
    // %1 = resourceClass, %2 = desktopId
    const QString js = QString::fromLatin1(R"JS(
var target = '%1';
var df     = '%2';
var wins = workspace.windowList().filter(function(w) {
    return w.resourceName    === target
        || w.desktopFileName === df
        || w.desktopFileName === target;
});
if (wins.length > 0) {
    var w = wins[0];
    if (w.minimized) {
        w.minimized = false;
        workspace.activeWindow = w;
    } else if (workspace.activeWindow === w) {
        w.minimized = true;
    } else {
        workspace.activeWindow = w;
    }
}
)JS").arg(resourceClass, e.desktopId);

    QFile f(path);
    if (!f.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        launch(index);   // fallback
        return;
    }
    f.write(js.toUtf8());
    f.close();

    QDBusInterface scripting(
        QStringLiteral("org.kde.KWin"),
        QStringLiteral("/Scripting"),
        QStringLiteral("org.kde.kwin.Scripting"));

    QDBusReply<int> reply = scripting.call(
        QStringLiteral("loadScript"), path, name);


    if (!reply.isValid() || reply.value() < 0) {
        QFile::remove(path);
        launch(index);   // fallback
        return;
    }

    const int scriptId = reply.value();
    const QString obj  = QStringLiteral("/Scripting/Script%1").arg(scriptId);


    QDBusInterface script(
        QStringLiteral("org.kde.KWin"), obj,
        QStringLiteral("org.kde.kwin.Script"));
    script.call(QStringLiteral("run"));

    // Unload and remove the temp file after the script has had time to run
    QTimer::singleShot(500, [name, path]() {
        QDBusInterface scripting(
            QStringLiteral("org.kde.KWin"),
            QStringLiteral("/Scripting"),
            QStringLiteral("org.kde.kwin.Scripting"));
        scripting.call(QStringLiteral("unloadScript"), name);
        QFile::remove(path);
    });
}

// ─────────────────────────────────────────────────────────────────────────────
// KConfig persistence
// Stored in ~/.config/plasma-dockrc under [Pinned] pinned=id1,id2,...
// On first run (no key present) falls back to s_defaultApps.
// ─────────────────────────────────────────────────────────────────────────────
void AppModel::setDockEdge(int edge)
{
    if (m_dockEdge == edge) return;
    m_dockEdge = edge;
    Q_EMIT dockEdgeChanged();
    KConfig cfg(QStringLiteral("plasma-dockrc"));
    cfg.group(QStringLiteral("General")).writeEntry("edge", edge);
    cfg.sync();
}

void AppModel::setDodgeEnabled(bool v)
{
    if (m_dodgeEnabled == v) return;
    m_dodgeEnabled = v;
    Q_EMIT dodgeEnabledChanged();
    KConfig cfg(QStringLiteral("plasma-dockrc"));
    cfg.group(QStringLiteral("General")).writeEntry("dodge", v);
    cfg.sync();
}

void AppModel::loadPinned()
{
    KConfig config(QStringLiteral("plasma-dockrc"));

    // General settings — read before pinned list so edge/dodge are ready
    KConfigGroup gen = config.group(QStringLiteral("General"));
    m_dockEdge     = gen.readEntry("edge",  1);
    m_dodgeEnabled = gen.readEntry("dodge", false);

    KConfigGroup grp = config.group(QStringLiteral("Pinned"));

    QStringList ids;
    if (grp.hasKey("pinned")) {
        ids = grp.readEntry("pinned", QStringList{});
    } else {
        ids = s_defaultApps;
        grp.writeEntry("pinned", ids);
    }

    for (const QString &id : ids) {
        AppEntry e = entryFromDesktopId(id);
        if (!e.name.isEmpty()) {
            m_entries.append(e);
            m_pinnedIds.insert(id);
        } else {
        }
    }

    if (m_entries.isEmpty()) {
        // Hard fallback — should never happen on a functioning KDE install
        const QList<AppEntry> fallback = {
            { "org.kde.dolphin", "Files",    "system-file-manager", "dolphin",         true, false },
            { "org.kde.konsole", "Terminal", "utilities-terminal",  "konsole",          true, false },
            { "org.kde.kate",    "Editor",   "kate",                "kate",             true, false },
            { "org.kde.discover","Discover", "plasmadiscover",      "plasma-discover",  true, false },
        };
        m_entries = fallback;
        for (const AppEntry &e : m_entries) m_pinnedIds.insert(e.desktopId);
    }
}

void AppModel::savePinned() const
{
    KConfig config(QStringLiteral("plasma-dockrc"));
    KConfigGroup grp = config.group(QStringLiteral("Pinned"));

    QStringList ids;
    for (const AppEntry &e : m_entries)
        if (e.pinned && !e.isSeparator)
            ids << e.desktopId;

    grp.writeEntry("pinned", ids);
    config.sync();
}

// ─────────────────────────────────────────────────────────────────────────────
// Private helpers
// ─────────────────────────────────────────────────────────────────────────────
int AppModel::separatorRow() const
{
    for (int i = 0; i < m_entries.size(); ++i)
        if (m_entries.at(i).isSeparator) return i;
    return -1;
}

void AppModel::addDynamicEntry(const QString &desktopId)
{
    for (const AppEntry &e : m_entries)
        if (e.desktopId == desktopId) return;

    AppEntry e = entryFromDesktopId(desktopId);
    if (e.name.isEmpty()) {
        e.desktopId = desktopId;
        e.name      = desktopId.section(QLatin1Char('.'), -1);
        e.iconName  = QStringLiteral("application-x-executable");
    }
    e.pinned = false;

    int sepRow = separatorRow();
    if (sepRow < 0) {
        sepRow = 0;
        for (int i = 0; i < m_entries.size(); ++i)
            if (m_entries.at(i).pinned) sepRow = i + 1;

        AppEntry sep;
        sep.isSeparator = true;
        sep.pinned      = false;
        beginInsertRows({}, sepRow, sepRow);
        m_entries.insert(sepRow, sep);
        endInsertRows();
        Q_EMIT countChanged();
    }

    const int insertAt = m_entries.size();
    beginInsertRows({}, insertAt, insertAt);
    m_entries.append(e);
    endInsertRows();
    Q_EMIT countChanged();
}

void AppModel::removeDynamicEntry(const QString &desktopId)
{
    for (int i = 0; i < m_entries.size(); ++i) {
        if (!m_entries.at(i).pinned && m_entries.at(i).desktopId == desktopId) {
            beginRemoveRows({}, i, i);
            m_entries.removeAt(i);
            endRemoveRows();
            Q_EMIT countChanged();
            break;
        }
    }

    bool hasDynamic = false;
    for (const AppEntry &e : m_entries)
        if (!e.pinned && !e.isSeparator) { hasDynamic = true; break; }

    if (!hasDynamic) {
        const int sep = separatorRow();
        if (sep >= 0) {
            beginRemoveRows({}, sep, sep);
            m_entries.removeAt(sep);
            endRemoveRows();
            Q_EMIT countChanged();
        }
    }
}

void AppModel::onRunningChanged(const QString &desktopId, bool running)
{
    Q_UNUSED(running)
    for (int i = 0; i < m_entries.size(); ++i) {
        if (m_entries.at(i).desktopId == desktopId) {
            const QModelIndex idx = index(i);
            Q_EMIT dataChanged(idx, idx, { RunningRole });
            return;
        }
    }
}

void AppModel::onUnknownAppStarted(const QString &desktopId)
{
    addDynamicEntry(desktopId);
}

void AppModel::onUnknownAppStopped(const QString &desktopId)
{
    removeDynamicEntry(desktopId);
}

AppEntry AppModel::entryFromDesktopId(const QString &desktopId) const
{
    KService::Ptr svc = KService::serviceByDesktopName(desktopId);
    if (!svc || !svc->isApplication() || svc->noDisplay()) return {};
    return AppEntry {
        .desktopId = desktopId,
        .name      = svc->name(),
        .iconName  = svc->icon(),
        .exec      = svc->exec(),
        .pinned    = true,
    };
}
