#pragma once

#include <QQuickWindow>

// LayerShellQt is KDE's official library for zwlr_layer_shell_v1.
// It intercepts wl_surface role assignment at the platform window level —
// before Qt's QPA can assign xdg_toplevel — which is the only correct
// way to do this in Qt6.
namespace LayerShellQt {
class Window;
}

class LayerShellWindow : public QQuickWindow
{
    Q_OBJECT
    Q_PROPERTY(Edge edge READ edge WRITE setEdge NOTIFY edgeChanged)
    Q_PROPERTY(int dockSize READ dockSize WRITE setDockSize NOTIFY dockSizeChanged)
    Q_PROPERTY(int exclusiveZone READ exclusiveZone WRITE setExclusiveZone NOTIFY exclusiveZoneChanged)

public:
    enum Edge { Top = 0, Bottom = 1, Left = 2, Right = 3 };
    Q_ENUM(Edge)

    explicit LayerShellWindow(QWindow *parent = nullptr);
    ~LayerShellWindow() override = default;

    Edge edge() const;
    void setEdge(Edge edge);

    int dockSize() const;
    void setDockSize(int px);

    int exclusiveZone() const;
    void setExclusiveZone(int px);

Q_SIGNALS:
    void edgeChanged();
    void dockSizeChanged();
    void exclusiveZoneChanged();
    void layerShellReady();

protected:
    void showEvent(QShowEvent *event) override;

private:
    void applyLayerShell();

    Edge                  m_edge       = Bottom;
    int                   m_dockSize   = 72;
    int                   m_exclusiveZone = 0;  // 0 = use dockSize
    bool                  m_applied  = false;
    LayerShellQt::Window *m_lsWindow = nullptr;
};
