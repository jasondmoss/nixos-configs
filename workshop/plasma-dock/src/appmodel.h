#pragma once

#include <QAbstractListModel>
#include <QSet>
#include <KService>

class WindowTracker;

struct AppEntry {
    QString desktopId;
    QString name;
    QString iconName;
    QString exec;
    bool    pinned      = true;
    bool    isSeparator = false;
};

class AppModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(int  count        READ rowCount    NOTIFY countChanged)
    Q_PROPERTY(int  dockEdge     READ dockEdge    WRITE setDockEdge     NOTIFY dockEdgeChanged)
    Q_PROPERTY(bool dodgeEnabled READ dodgeEnabled WRITE setDodgeEnabled NOTIFY dodgeEnabledChanged)

public:
    enum Roles {
        DesktopIdRole   = Qt::UserRole + 1,
        NameRole,
        IconNameRole,
        ExecRole,
        RunningRole,
        IsSeparatorRole,
        IsPinnedRole,
    };
    Q_ENUM(Roles)

    explicit AppModel(QObject *parent = nullptr);

    int      rowCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    int  dockEdge()     const { return m_dockEdge; }
    bool dodgeEnabled() const { return m_dodgeEnabled; }
    Q_INVOKABLE void setDockEdge(int edge);
    Q_INVOKABLE void setDodgeEnabled(bool v);

    Q_INVOKABLE void launch(int index) const;
    Q_INVOKABLE void activateOrLaunch(int index);
    Q_INVOKABLE void moveApp(int from, int to);
    Q_INVOKABLE void pinApp(const QString &desktopId);
    Q_INVOKABLE void unpinApp(int index);

Q_SIGNALS:
    void countChanged();
    void dockEdgeChanged();
    void dodgeEnabledChanged();

private:
    void loadPinned();
    void savePinned() const;
    AppEntry entryFromDesktopId(const QString &desktopId) const;

    int  separatorRow() const;
    void addDynamicEntry(const QString &desktopId);
    void removeDynamicEntry(const QString &desktopId);

    QList<AppEntry> m_entries;
    WindowTracker  *m_tracker     = nullptr;
    QSet<QString>   m_pinnedIds;
    int             m_dockEdge    = 1;     // 1 = Bottom
    bool            m_dodgeEnabled = false;

private Q_SLOTS:
    void onRunningChanged(const QString &desktopId, bool running);
    void onUnknownAppStarted(const QString &desktopId);
    void onUnknownAppStopped(const QString &desktopId);
};
