#include "dodgemanager.h"
#include "dockadaptor.h"

#include <QDBusConnection>
#include <QDBusInterface>
#include <QDBusReply>
#include <QDateTime>
#include <QFile>
#include <QScreen>
#include <QGuiApplication>

DodgeManager::DodgeManager(QObject *parent)
    : QObject(parent)
{
    // Adaptor must be created before registerObject.
    new DockAdaptor(this);

    // Register immediately — the service must be present before any KWin
    // script tries to call back, regardless of whether dodge is enabled.
    QDBusConnection bus = QDBusConnection::sessionBus();
    bool svcOk = bus.registerService(QStringLiteral("org.kde.plasma-dock"));
    bool objOk = bus.registerObject(
        QStringLiteral("/dock"),
        this,
        QDBusConnection::ExportAdaptors);
    m_busRegistered = svcOk && objOk;
}

DodgeManager::~DodgeManager()
{
    unloadScript();
    QDBusConnection::sessionBus().unregisterObject(QStringLiteral("/dock"));
    QDBusConnection::sessionBus().unregisterService(QStringLiteral("org.kde.plasma-dock"));
}

void DodgeManager::start(int screenW, int screenH, int dockSize, int edge)
{

    // Always unload stale scripts first — handles leftovers from a killed process.
    unloadScript();

    if (!m_busRegistered) {
        return;
    }

    loadScript(screenW, screenH, dockSize, edge);
}

void DodgeManager::setOverlapping(bool value)
{
    if (m_overlapping == value) return;
    m_overlapping = value;
    Q_EMIT overlappingChanged();
}

void DodgeManager::loadScript(int screenW, int screenH, int dockSize, int edge)
{
    m_scriptName = QStringLiteral("plasma-dock-dodge-%1")
        .arg(QDateTime::currentMSecsSinceEpoch());

    // Compute dock rect from edge + dimensions
    // edge: 0=Top 1=Bottom 2=Left 3=Right
    int rx = 0, ry = 0, rw = 0, rh = 0;
    switch (edge) {
    case 0: rx = 0;             ry = 0;              rw = screenW; rh = dockSize; break; // Top
    case 1: rx = 0;             ry = screenH-dockSize; rw = screenW; rh = dockSize; break; // Bottom
    case 2: rx = 0;             ry = 0;              rw = dockSize; rh = screenH; break; // Left
    case 3: rx = screenW-dockSize; ry = 0;           rw = dockSize; rh = screenH; break; // Right
    }

    const QString path = QStringLiteral("/tmp/%1.js").arg(m_scriptName);

    // Persistent KWin script.  Connects to workspace signals once, stays
    // alive for the dock's lifetime.  callDBus() routes back to setOverlapping.
    const QString js = QString::fromLatin1(R"JS(
var dockX = %1, dockY = %2, dockW = %3, dockH = %4;

function isNormalWindow(w) {
    if (w.minimized) return false;
    var rc = w.resourceClass;
    return rc !== "plasmashell"
        && rc !== "plasma-dock"
        && rc !== "krunner"
        && rc !== "conky"
        && rc !== "ksmserver"
        && rc !== "kwin_wayland"
        && rc !== "kded6";
}

function rectsOverlap(ax, ay, aw, ah, bx, by, bw, bh) {
    return ax < bx + bw && ax + aw > bx
        && ay < by + bh && ay + ah > by;
}

function checkOverlap() {
    var wins = workspace.windowList();
    var overlap = false;
    for (var i = 0; i < wins.length; i++) {
        var w = wins[i];
        if (!isNormalWindow(w)) continue;
        var g = w.frameGeometry;
        if (rectsOverlap(g.x, g.y, g.width, g.height,
                         dockX, dockY, dockW, dockH)) {
            overlap = true;
            break;
        }
    }
    callDBus("org.kde.plasma-dock", "/dock",
             "org.kde.plasma_dock", "setOverlapping", overlap ? 1 : 0);
}

function connectWindow(w) {
    w.frameGeometryChanged.connect(checkOverlap);
    w.minimizedChanged.connect(checkOverlap);
    w.fullScreenChanged.connect(checkOverlap);
}

// Wire up windows already open when the script loads
var existing = workspace.windowList();
for (var i = 0; i < existing.length; i++) {
    connectWindow(existing[i]);
}

workspace.windowAdded.connect(function(w) {
    connectWindow(w);
    checkOverlap();
});
workspace.windowRemoved.connect(checkOverlap);

// Seed initial state
checkOverlap();
)JS").arg(rx).arg(ry).arg(rw).arg(rh);

    QFile f(path);
    if (!f.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        return;
    }
    f.write(js.toUtf8());
    f.close();

    QDBusInterface scripting(
        QStringLiteral("org.kde.KWin"),
        QStringLiteral("/Scripting"),
        QStringLiteral("org.kde.kwin.Scripting"));

    QDBusReply<int> reply = scripting.call(
        QStringLiteral("loadScript"), path, m_scriptName);


    if (!reply.isValid() || reply.value() < 0) {
        QFile::remove(path);
        return;
    }

    const int id  = reply.value();
    const QString obj = QStringLiteral("/Scripting/Script%1").arg(id);
    QDBusInterface script(
        QStringLiteral("org.kde.KWin"), obj,
        QStringLiteral("org.kde.kwin.Script"));
    auto runReply = script.call(QStringLiteral("run"));
}

void DodgeManager::unloadScript()
{
    if (m_scriptName.isEmpty()) return;
    QDBusInterface scripting(
        QStringLiteral("org.kde.KWin"),
        QStringLiteral("/Scripting"),
        QStringLiteral("org.kde.kwin.Scripting"));
    scripting.call(QStringLiteral("unloadScript"), m_scriptName);
    QFile::remove(QStringLiteral("/tmp/%1.js").arg(m_scriptName));
    m_scriptName.clear();
}
