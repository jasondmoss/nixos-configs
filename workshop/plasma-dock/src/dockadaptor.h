#pragma once

// ─────────────────────────────────────────────────────────────────────────────
// DockAdaptor — minimal D-Bus adaptor for DodgeManager.
//
// QDBusAbstractAdaptor is the correct Qt mechanism for exposing a C++ object
// on the session bus with a specific interface name.  Unlike ExportAllSlots,
// it generates proper D-Bus introspection XML so callDBus() in KWin scripts
// can find and verify the method signature at runtime.
// ─────────────────────────────────────────────────────────────────────────────

#include <QDBusAbstractAdaptor>

class DodgeManager;

class DockAdaptor : public QDBusAbstractAdaptor
{
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "org.kde.plasma_dock")

public:
    explicit DockAdaptor(DodgeManager *parent);

public Q_SLOTS:
    void setOverlapping(bool value);
    void setOverlapping(int value);   // KWin callDBus may pass bool as int variant

private:
    DodgeManager *m_manager;
};
