#pragma once

#include <QObject>

// DodgeManager
//
// Loads a persistent KWin JS script that watches all window geometry and
// calls back to us via D-Bus when a window overlaps the dock rect.
// We register org.kde.plasma-dock / /dock on the session bus.
// setOverlapping() is a public slot so Qt exports it correctly via
// ExportAllSlots — callDBus() in KWin can then reach it.

class DodgeManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool overlapping READ overlapping NOTIFY overlappingChanged)

public:
    explicit DodgeManager(QObject *parent = nullptr);
    ~DodgeManager() override;

    bool overlapping() const { return m_overlapping; }

    // Called from QML once the screen geometry is known.
    // edge: 0=Top 1=Bottom 2=Left 3=Right
    Q_INVOKABLE void start(int screenW, int screenH, int dockSize, int edge);

Q_SIGNALS:
    void overlappingChanged();

public Q_SLOTS:
    // Called back by the KWin script via callDBus().
    // Must be a slot (not just Q_INVOKABLE) for ExportAllSlots to expose it.
    void setOverlapping(bool value);

private:
    void loadScript(int screenW, int screenH, int dockSize, int edge);
    void unloadScript();

    bool    m_overlapping  = false;
    bool    m_busRegistered = false;
    QString m_scriptName;
};
