#include "layershellwindow.h"

#include <QScreen>
#include <QShowEvent>

// LayerShellQt — intercepts wl_surface role assignment before Qt's QPA
// can assign xdg_toplevel.  Must be included and Window::get() called
// before the platform window is fully initialised.
#include <LayerShellQt/Window>
#include <KWindowEffects>

// ─────────────────────────────────────────────────────────────────────────────
// Constructor
// ─────────────────────────────────────────────────────────────────────────────
LayerShellWindow::LayerShellWindow(QWindow *parent)
    : QQuickWindow(parent)
{
    setColor(Qt::transparent);

    // Get the LayerShellQt wrapper for this window immediately — before show().
    // This is what prevents Qt from assigning xdg_toplevel: LayerShellQt
    // registers itself as the shell integration and claims the surface role.
    m_lsWindow = LayerShellQt::Window::get(this);

    connect(this, &QQuickWindow::screenChanged,
            this, [this]() { if (m_applied) applyLayerShell(); });
}

// ─────────────────────────────────────────────────────────────────────────────
// Properties
// ─────────────────────────────────────────────────────────────────────────────
LayerShellWindow::Edge LayerShellWindow::edge() const { return m_edge; }

void LayerShellWindow::setEdge(Edge edge)
{
    if (m_edge == edge) return;
    m_edge = edge;
    Q_EMIT edgeChanged();
    if (m_applied) applyLayerShell();
}

int LayerShellWindow::dockSize() const { return m_dockSize; }

int LayerShellWindow::exclusiveZone() const { return m_exclusiveZone; }

void LayerShellWindow::setExclusiveZone(int px)
{
    if (m_exclusiveZone == px) return;
    m_exclusiveZone = px;
    Q_EMIT exclusiveZoneChanged();
    if (m_applied) applyLayerShell();
}

void LayerShellWindow::setDockSize(int px)
{
    if (m_dockSize == px) return;
    m_dockSize = px;
    Q_EMIT dockSizeChanged();
    if (m_applied) applyLayerShell();
}

// ─────────────────────────────────────────────────────────────────────────────
// showEvent — configure layer shell on first show
// ─────────────────────────────────────────────────────────────────────────────
void LayerShellWindow::showEvent(QShowEvent *event)
{
    QQuickWindow::showEvent(event);
    if (!m_applied) {
        applyLayerShell();
        m_applied = true;
        Q_EMIT layerShellReady();
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// applyLayerShell — configure via LayerShellQt API
// ─────────────────────────────────────────────────────────────────────────────
void LayerShellWindow::applyLayerShell()
{
    if (!m_lsWindow) {
        qWarning() << "[PlasmaDock] LayerShellQt::Window not available.";
        return;
    }

    // Layer — TOP sits above normal windows, below lockscreens.
    m_lsWindow->setLayer(LayerShellQt::Window::LayerTop);

    // Anchoring — Bottom edge: pin to bottom, stretch full width.
    using Anchors = LayerShellQt::Window::Anchors;
    switch (m_edge) {
    case Bottom:
        m_lsWindow->setAnchors(Anchors(LayerShellQt::Window::AnchorBottom
                                     | LayerShellQt::Window::AnchorLeft
                                     | LayerShellQt::Window::AnchorRight));
        break;
    case Top:
        m_lsWindow->setAnchors(Anchors(LayerShellQt::Window::AnchorTop
                                     | LayerShellQt::Window::AnchorLeft
                                     | LayerShellQt::Window::AnchorRight));
        break;
    case Left:
        m_lsWindow->setAnchors(Anchors(LayerShellQt::Window::AnchorLeft
                                     | LayerShellQt::Window::AnchorTop
                                     | LayerShellQt::Window::AnchorBottom));
        break;
    case Right:
        m_lsWindow->setAnchors(Anchors(LayerShellQt::Window::AnchorRight
                                     | LayerShellQt::Window::AnchorTop
                                     | LayerShellQt::Window::AnchorBottom));
        break;
    }

    // Exclusive zone — reserve exactly as many pixels as the dock is thick.
    m_lsWindow->setExclusiveZone(m_exclusiveZone > 0 ? m_exclusiveZone : m_dockSize);

    // Keyboard — only grab focus on explicit click, never steal from apps.
    // None: dock never steals keyboard focus, so clicking an icon does not
    // change the active window — workspace.activateWindow() works correctly.
    m_lsWindow->setKeyboardInteractivity(
        LayerShellQt::Window::KeyboardInteractivityNone);

    // LayerShellQt handles the "fill" axis via anchoring — we only need to set
    // the thickness dimension.  Setting the other axis to a non-zero value
    // (screen width/height) is fine; the compositor overrides it from anchoring.
    // Setting it to 0 results in a zero-size QQuickWindow and nothing renders.
    bool horizontal = (m_edge == Top || m_edge == Bottom);
    if (horizontal) {
        setWidth(screen() ? screen()->size().width() : 1920);
        setHeight(m_dockSize);
    } else {
        setWidth(m_dockSize);
        setHeight(screen() ? screen()->size().height() : 1080);
    }

    // Request compositor blur behind the window.
    // KWindowEffects::enableBlurBehind passes a null region to blur the
    // entire window area — KWin Plasma 6 respects this on Wayland.
    KWindowEffects::enableBlurBehind(this);
}
