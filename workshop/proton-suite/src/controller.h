#pragma once
#include <QObject>
#include <KStatusNotifierItem>
#include <QPointer>
#include <QQuickWindow>

class Controller
    : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool visible READ isVisible WRITE setVisible NOTIFY visibleChanged)

public:
//    explicit Controller(QObject *parent = nullptr);
    explicit Controller(QObject *parent = nullptr, bool startMinimized = false);

    void setWindow(QQuickWindow* window);
    bool isVisible() const;

    // ADDED: Override standard event filter to handle closing safely
    bool eventFilter(QObject *watched, QEvent *event) override;

public: // "public slots" removed to satisfy Cppcheck
    void toggleWindow();
    void setVisible(bool visible);
    void activate();
    void quit();

signals:
    void visibleChanged();

private:
    void setupTray();
    void setupGlobalShortcut();

    KStatusNotifierItem *m_tray;
    QPointer<QQuickWindow> m_window;
    bool m_isVisible;
};
