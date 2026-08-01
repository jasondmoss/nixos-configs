/*
    SPDX-License-Identifier: GPL-2.0-or-later
*/

#include "spacialdesktop.h"
#include "gridshader.h"
#include "spacialdesktopconfig.h"

#include "core/output.h"
#include "core/renderviewport.h"
#include "effect/effecthandler.h"
#include "effect/effectwindow.h"
#include "opengl/glshader.h"
#include "opengl/glshadermanager.h"
#include "opengl/glvertexbuffer.h"
#include "options.h"
#include "window.h"

#include <QEasingCurve>
#include <QLineF>

#include <epoxy/gl.h>

namespace
{
constexpr double DragThresholdPx = 8.0;

// Grid look dials from Desktop5's config.js (venue-tuned there; constants here)
constexpr float GridCorePx = 1.5f;
constexpr float GridGlowPx = 6.0f;
constexpr float GridGlowStrength = 0.5f;
constexpr float GridEdgeFadeStart = 0.65f;
constexpr float GridEdgeFadeFloor = 0.35f;
constexpr std::chrono::milliseconds GridFadeDuration{200};

// Shake-to-stash dials from Desktop5's config.js
constexpr double ShakeMinTravel = 20.0;
constexpr std::chrono::milliseconds ShakeWindow{500};
constexpr int ShakeCount = 4;
constexpr double StashGapPx = 24.0;

// Drag rails dials from Desktop5's config.js
constexpr float RailGain = 1.6f;
constexpr float RailThickness = 2.2f;
constexpr std::chrono::milliseconds RailFadeIn{150};
constexpr std::chrono::milliseconds RailFadeOut{250};
}

namespace KWin
{

SpacialDesktopEffect::SpacialDesktopEffect()
{
    SpacialDesktopConfig::instance(effects->config());
    reconfigure(ReconfigureAll);

    if (effects->isOpenGLCompositing()) {
        m_gridShader = ShaderManager::instance()->generateCustomShader(
            ShaderTrait::MapTexture, QByteArray(), s_gridFragmentSource);
        if (m_gridShader) {
            m_gridUniforms.gridColor = m_gridShader->uniformLocation("gridColor");
            m_gridUniforms.deadZone = m_gridShader->uniformLocation("deadZones");
            m_gridUniforms.power = m_gridShader->uniformLocation("power");
            m_gridUniforms.strength = m_gridShader->uniformLocation("strength");
            m_gridUniforms.halfCellsX = m_gridShader->uniformLocation("halfCellsX");
            m_gridUniforms.halfCellsY = m_gridShader->uniformLocation("halfCellsY");
            m_gridUniforms.corePx = m_gridShader->uniformLocation("corePx");
            m_gridUniforms.glowPx = m_gridShader->uniformLocation("glowPx");
            m_gridUniforms.glowStrength = m_gridShader->uniformLocation("glowStrength");
            m_gridUniforms.intensity = m_gridShader->uniformLocation("intensity");
            m_gridUniforms.fadeStart = m_gridShader->uniformLocation("fadeStart");
            m_gridUniforms.fadeFloor = m_gridShader->uniformLocation("fadeFloor");
            m_gridUniforms.backdrop = m_gridShader->uniformLocation("backdrop");
            m_gridUniforms.gridOpacity = m_gridShader->uniformLocation("gridOpacity");
            m_gridUniforms.dragActive = m_gridShader->uniformLocation("dragActive");
            m_gridUniforms.dragBand = m_gridShader->uniformLocation("dragBand");
            m_gridUniforms.railGain = m_gridShader->uniformLocation("railGain");
            m_gridUniforms.railThickness = m_gridShader->uniformLocation("railThickness");
        }
    }
    m_railTimeline = TimeLine(RailFadeOut, TimeLine::Backward);
    m_railTimeline.setEasingCurve(QEasingCurve::InOutSine);
    m_railTimeline.setElapsed(RailFadeOut);
    // Drag-only grid mode: value() is the grid opacity; starts fully faded out.
    m_gridTimeline = TimeLine(GridFadeDuration, TimeLine::Backward);
    m_gridTimeline.setEasingCurve(QEasingCurve::InOutSine);
    m_gridTimeline.setElapsed(GridFadeDuration);

    connect(effects, &EffectsHandler::windowAdded, this, &SpacialDesktopEffect::slotWindowAdded);
    connect(effects, &EffectsHandler::windowDeleted, this, &SpacialDesktopEffect::slotWindowDeleted);
    connect(effects, &EffectsHandler::mouseChanged, this, &SpacialDesktopEffect::slotMouseChanged);
    connect(effects, &EffectsHandler::virtualScreenGeometryChanged, this, [this]() {
        // Output layout changed under us: abort any drag; parked windows are
        // real geometry, KWin's own output handling relocates them.
        m_drag = DragState();
    });

    const auto windows = effects->stackingOrder();
    for (EffectWindow *w : windows) {
        slotWindowAdded(w);
    }
}

SpacialDesktopEffect::~SpacialDesktopEffect()
{
    // Don't leave windows stranded as minimized miniatures when the effect is
    // unloaded — hand them back as regular unminimized windows.
    for (auto it = m_windows.begin(); it != m_windows.end(); ++it) {
        if (it->miniature) {
            it->visibleRef = EffectWindowVisibleRef();
            it.key()->setMinimized(false);
        }
    }
}

bool SpacialDesktopEffect::supported()
{
    return effects->animationsSupported();
}

void SpacialDesktopEffect::reconfigure(ReconfigureFlags)
{
    SpacialDesktopConfig::self()->read();
    const double dz = SpacialDesktopConfig::warpDeadZone();
    m_warp.deadZoneLeft = SpacialDesktopConfig::parkLeft() ? dz : 1.0;
    m_warp.deadZoneRight = SpacialDesktopConfig::parkRight() ? dz : 1.0;
    m_warp.power = SpacialDesktopConfig::warpPower();
    m_warp.strength = SpacialDesktopConfig::warpStrength();
    m_warp.minScale = SpacialDesktopConfig::minScale();
    m_columnInner = SpacialDesktopConfig::columnInner();
    m_columnOuter = SpacialDesktopConfig::columnOuter();
    m_animate = SpacialDesktopConfig::animationsEnabled();
    m_miniatureParking = SpacialDesktopConfig::miniatureParking();
    m_duration = Effect::animationTime(std::chrono::milliseconds(SpacialDesktopConfig::animationDuration()));
    m_gridMode = SpacialDesktopConfig::gridMode();
    m_gridColor = SpacialDesktopConfig::gridColor();
    m_gridCellPx = SpacialDesktopConfig::gridCellSize();
    m_gridIntensity = SpacialDesktopConfig::gridIntensity();
    m_gridBackdrop = SpacialDesktopConfig::gridBackdrop();
    m_shakeToStash = SpacialDesktopConfig::shakeToStash();
    m_dragRails = SpacialDesktopConfig::dragRails();
    effects->addRepaintFull();
}

bool SpacialDesktopEffect::isActive() const
{
    const bool gridActive = m_gridShader
        && (m_gridMode == GridAlways
            || (m_gridMode == GridDuringDrag && (m_drag.window || !m_gridTimeline.done())));
    return AnimationEffect::isActive() || m_drag.window || hasMiniatures() || gridActive;
}

bool SpacialDesktopEffect::hasMiniatures() const
{
    for (const WindowState &st : m_windows) {
        if (st.miniature) {
            return true;
        }
    }
    return false;
}

int SpacialDesktopEffect::requestedEffectChainPosition() const
{
    return 50;
}

bool SpacialDesktopEffect::isRelevant(EffectWindow *w) const
{
    return w && w->isNormalWindow() && w->isMovable() && !w->isSpecialWindow()
        && !w->isFullScreen() && !w->isDeleted() && w->screen()
        && w->window() && w->window()->maximizeMode() == MaximizeRestore;
}

void SpacialDesktopEffect::slotWindowAdded(EffectWindow *w)
{
    connect(w, &EffectWindow::windowStartUserMovedResized,
            this, &SpacialDesktopEffect::slotWindowStartUserMovedResized);
    connect(w, &EffectWindow::windowStepUserMovedResized,
            this, &SpacialDesktopEffect::slotWindowStepUserMovedResized);
    connect(w, &EffectWindow::windowFinishUserMovedResized,
            this, &SpacialDesktopEffect::slotWindowFinishUserMovedResized);
    connect(w, &EffectWindow::windowFrameGeometryChanged,
            this, &SpacialDesktopEffect::slotWindowFrameGeometryChanged);
    connect(w, &EffectWindow::windowDamaged,
            this, &SpacialDesktopEffect::slotWindowDamaged);
    connect(w, &EffectWindow::minimizedChanged,
            this, &SpacialDesktopEffect::slotMinimizedChanged);
}

RectF SpacialDesktopEffect::currentMiniRect(const WindowState &st)
{
    const double t = st.miniTimeline.value();
    const RectF &a = st.miniFrom;
    const RectF &b = st.miniRect;
    return RectF(a.x() + (b.x() - a.x()) * t,
                 a.y() + (b.y() - a.y()) * t,
                 a.width() + (b.width() - a.width()) * t,
                 a.height() + (b.height() - a.height()) * t);
}

RectF SpacialDesktopEffect::miniaturePaintedExtents(EffectWindow *w, const RectF &paintedFrameRect)
{
    // The painted footprint exceeds the frame rect: the shadow and decoration
    // (expandedGeometry) scale along with it, and the scaled rect has
    // fractional right/bottom edges that must not round out of the repaint
    // region — both otherwise show up as a clipped-looking miniature.
    const RectF frame = w->frameGeometry();
    const RectF expanded = w->expandedGeometry();
    const double factor = paintedFrameRect.width() / frame.width();
    return RectF(paintedFrameRect.x() + (expanded.x() - frame.x()) * factor,
                 paintedFrameRect.y() + (expanded.y() - frame.y()) * factor,
                 expanded.width() * factor,
                 expanded.height() * factor)
        .adjusted(-2.0, -2.0, 2.0, 2.0);
}

void SpacialDesktopEffect::slotWindowDamaged(EffectWindow *w)
{
    const auto it = m_windows.constFind(w);
    if (it != m_windows.constEnd() && it->miniature) {
        effects->addRepaint(miniaturePaintedExtents(w, currentMiniRect(*it)));
    }
}

void SpacialDesktopEffect::slotMinimizedChanged(EffectWindow *w)
{
    // Any unminimize — our click-to-restore, the taskbar, alt-tab — restores a
    // miniature-parked window to its untouched natural geometry.
    const auto it = m_windows.find(w);
    if (it != m_windows.end() && it->miniature && !w->isMinimized()) {
        if (m_unparkByDrag) {
            // Grab-out: stop painting the miniature but keep `parked` set so
            // the drag's finish handler goes through the restore/re-park
            // branches instead of the plain-move early return.
            it->miniature = false;
            it->visibleRef = EffectWindowVisibleRef();
        } else {
            unparkMiniature(w, *it);
        }
    }
}

void SpacialDesktopEffect::slotMouseChanged(const QPointF &pos, const QPointF &oldpos,
                                            Qt::MouseButtons buttons, Qt::MouseButtons oldbuttons,
                                            Qt::KeyboardModifiers modifiers, Qt::KeyboardModifiers oldmodifiers)
{
    Q_UNUSED(oldpos)
    Q_UNUSED(modifiers)
    Q_UNUSED(oldmodifiers)
    // Input hit-testing ignores miniatures (the real window is minimized), so
    // this passive observation is their interaction channel. A press inside a
    // miniature arms a pending grab: releasing within the drag threshold is a
    // click (restore to natural geometry), moving beyond it re-grabs the
    // window into a real drag along the warp curve.
    if (m_pendingGrab.window) {
        EffectWindow *w = m_pendingGrab.window;
        const auto it = m_windows.constFind(w);
        if (it == m_windows.constEnd() || !it->miniature) {
            m_pendingGrab = PendingGrab();
        } else if (!(buttons & Qt::LeftButton)) {
            m_pendingGrab = PendingGrab();
            setMinimizedQuietly(w, false); // slotMinimizedChanged does the rest
            effects->activateWindow(w);
            return;
        } else if (QLineF(m_pendingGrab.pressPos, pos).length() > DragThresholdPx) {
            beginMiniatureDrag(w, pos);
            return;
        } else {
            return; // holding still within the threshold
        }
    }

    if (!(buttons & Qt::LeftButton) || (oldbuttons & Qt::LeftButton)) {
        return;
    }
    // Iterate topmost-first so overlapping miniatures resolve like windows do.
    const auto order = effects->stackingOrder();
    for (auto it = order.crbegin(); it != order.crend(); ++it) {
        const auto st = m_windows.constFind(*it);
        if (st != m_windows.constEnd() && st->miniature && st->miniRect.contains(pos)) {
            m_pendingGrab.window = *it;
            m_pendingGrab.pressPos = pos;
            m_pendingGrab.grabFrac = QPointF((pos.x() - st->miniRect.x()) / st->miniRect.width(),
                                             (pos.y() - st->miniRect.y()) / st->miniRect.height());
            return;
        }
    }
}

void SpacialDesktopEffect::beginMiniatureDrag(EffectWindow *w, const QPointF &cursorPos)
{
    const auto it = m_windows.constFind(w);
    const RectF mini = it->miniRect;
    const QPointF grabFrac = m_pendingGrab.grabFrac;
    m_pendingGrab = PendingGrab();

    // Unminimize without the restore animation; `parked` stays set (see
    // slotMinimizedChanged) so the finish handler restores or re-parks.
    m_unparkByDrag = true;
    setMinimizedQuietly(w, false);
    m_unparkByDrag = false;

    // Seed the drag with the miniature's geometry instead of the (full-size,
    // centrally-located) real frame, so the painted window starts exactly
    // where the miniature was and slides out along the curve.
    const RectF screen = w->screen()->geometryF();
    m_dragOverride.window = w;
    m_dragOverride.grabFrac = grabFrac;
    m_dragOverride.logicalOffset =
        Warp::warpForward(Warp::xNorm(mini.center().x(), screen.x(), screen.width()), m_warp)
        - Warp::warpForward(Warp::xNorm(cursorPos.x(), screen.x(), screen.width()), m_warp);

    effects->activateWindow(w);
    if (Window *window = w->window()) {
        window->performMousePressCommand(Options::MouseUnrestrictedMove, cursorPos);
    }
    m_dragOverride = DragOverride();
}

void SpacialDesktopEffect::slotWindowDeleted(EffectWindow *w)
{
    m_windows.remove(w);
    if (m_drag.window == w) {
        m_drag = DragState();
    }
    if (m_pendingGrab.window == w) {
        m_pendingGrab = PendingGrab();
    }
}

void SpacialDesktopEffect::slotWindowStartUserMovedResized(EffectWindow *w)
{
    if (!w->isUserMove() || w->isUserResize()) {
        // A user-initiated resize of a parked window means the user takes
        // ownership of its size again — stop tracking it as parked.
        if (w->isUserResize()) {
            m_windows.remove(w);
        }
        return;
    }
    if (!isRelevant(w)) {
        return;
    }

    WindowState &st = m_windows[w];
    const RectF frame = w->frameGeometry();
    if (!st.parked) {
        st.naturalGeometry = frame;
    }

    const QPointF cursor = effects->cursorPos();
    m_drag.window = w;
    m_drag.startFrame = frame;
    m_drag.shakeLastX = cursor.x();
    m_drag.grabFrac = QPointF((cursor.x() - frame.x()) / frame.width(),
                              (cursor.y() - frame.y()) / frame.height());

    const RectF screen = w->screen()->geometryF();
    const double uCursor = Warp::warpForward(Warp::xNorm(cursor.x(), screen.x(), screen.width()), m_warp);
    const double uCenter = Warp::warpForward(Warp::xNorm(frame.center().x(), screen.x(), screen.width()), m_warp);
    m_drag.logicalOffset = uCenter - uCursor;

    if (m_dragOverride.window == w) {
        // Drag started by grabbing a miniature: anchor to where the miniature
        // was, not to the full-size real frame.
        m_drag.grabFrac = m_dragOverride.grabFrac;
        m_drag.logicalOffset = m_dragOverride.logicalOffset;
    }

    if (m_gridMode == GridDuringDrag && m_gridTimeline.direction() != TimeLine::Forward) {
        m_gridTimeline.toggleDirection();
        effects->addRepaintFull();
    }
    if (m_dragRails && m_gridMode != GridOff && m_railTimeline.direction() != TimeLine::Forward) {
        m_railTimeline.setDuration(RailFadeIn);
        m_railTimeline.toggleDirection();
        effects->addRepaintFull();
    }

    updateDrag();
}

void SpacialDesktopEffect::slotWindowStepUserMovedResized(EffectWindow *w, const RectF &geometry)
{
    // The signal's geometry is KWin's own unwarped move-loop rect; the painted
    // position is derived from the cursor instead.
    Q_UNUSED(geometry)
    if (w != m_drag.window) {
        return;
    }
    updateDrag();
    if (m_shakeToStash && !m_drag.shook) {
        detectShake(effects->cursorPos().x());
    }
    effects->addRepaintFull();
}

void SpacialDesktopEffect::detectShake(double cursorX)
{
    // Desktop5's gesture: >= ShakeCount horizontal direction reversals, each
    // after >= ShakeMinTravel px, inside a rolling ShakeWindow — filters
    // ordinary dragging while catching a deliberate wiggle.
    const double dx = cursorX - m_drag.shakeLastX;
    if (std::abs(dx) < ShakeMinTravel) {
        return;
    }
    const int dir = (dx > 0) ? 1 : -1;
    if (m_drag.shakeDir != 0 && dir != m_drag.shakeDir) {
        const auto now = std::chrono::steady_clock::now();
        m_drag.shakeTimes.push_back(now);
        std::erase_if(m_drag.shakeTimes, [now](const auto &t) {
            return now - t > ShakeWindow;
        });
        if (int(m_drag.shakeTimes.size()) >= ShakeCount) {
            m_drag.shook = true;
            m_drag.shakeTimes.clear();
            stashAll(m_drag.window);
        }
    }
    m_drag.shakeDir = dir;
    m_drag.shakeLastX = cursorX;
}

void SpacialDesktopEffect::stashAll(EffectWindow *exclude)
{
    const RectF screen = exclude->screen()->geometryF();
    const RectF workArea = effects->clientArea(PlacementArea, exclude);
    const double screenCenterX = screen.center().x();

    // Collect every other full-size window, topmost first (recency order —
    // recent windows get the inner, larger columns).
    std::vector<EffectWindow *> candidates;
    const auto order = effects->stackingOrder();
    for (auto it = order.crbegin(); it != order.crend(); ++it) {
        EffectWindow *w = *it;
        if (w == exclude || !isRelevant(w) || w->isMinimized() || !w->isOnCurrentDesktop()) {
            continue;
        }
        const auto st = m_windows.constFind(w);
        if (st != m_windows.constEnd() && st->parked) {
            continue;
        }
        candidates.push_back(w);
    }
    if (candidates.empty()) {
        return;
    }

    // Split by which half of the screen the window currently occupies (when
    // both sides have park zones — otherwise everything goes to the enabled
    // side), then fill each side's inner column until it is height-full and
    // overflow to the outer column.
    const bool leftOn = Warp::sideEnabled(-1.0, m_warp);
    const bool rightOn = Warp::sideEnabled(1.0, m_warp);
    if (!leftOn && !rightOn) {
        return;
    }
    struct Column {
        std::vector<EffectWindow *> windows;
        double colXNorm;
        double height = 0.0;
    };
    for (const double side : {-1.0, 1.0}) {
        if (!Warp::sideEnabled(side, m_warp)) {
            continue;
        }
        Column inner{{}, Warp::columnX(side, m_columnInner, m_warp)};
        Column outer{{}, Warp::columnX(side, m_columnOuter, m_warp)};
        const double innerScale = Warp::windowScale(inner.colXNorm, m_warp);
        for (EffectWindow *w : candidates) {
            if (leftOn && rightOn
                && (w->frameGeometry().center().x() < screenCenterX) != (side < 0)) {
                continue;
            }
            const double h = w->frameGeometry().height() * innerScale;
            if (inner.height + h + StashGapPx <= workArea.height() || inner.windows.empty()) {
                inner.windows.push_back(w);
                inner.height += h + StashGapPx;
            } else {
                outer.windows.push_back(w);
            }
        }
        for (Column *col : {&inner, &outer}) {
            if (col->windows.empty()) {
                continue;
            }
            const double sc = Warp::windowScale(col->colXNorm, m_warp);
            const double colX = Warp::xPixel(col->colXNorm, screen.x(), screen.width());
            double total = -StashGapPx;
            for (EffectWindow *w : col->windows) {
                total += w->frameGeometry().height() * sc + StashGapPx;
            }
            double y = std::max(workArea.top() + StashGapPx,
                                workArea.center().y() - total / 2.0);
            for (EffectWindow *w : col->windows) {
                WindowState &st = m_windows[w];
                const RectF frame = w->frameGeometry();
                if (!st.parked) {
                    st.naturalGeometry = frame;
                }
                QSizeF size = st.naturalGeometry.size() * sc;
                RectF target(QPointF(colX - size.width() / 2.0, y), size);
                if (target.bottom() > workArea.bottom()) {
                    target.moveBottom(workArea.bottom());
                }
                if (target.right() > workArea.right() - 4.0) {
                    target.moveRight(workArea.right() - 4.0);
                }
                if (target.left() < workArea.left() + 4.0) {
                    target.moveLeft(workArea.left() + 4.0);
                }
                if (m_miniatureParking) {
                    parkMiniature(w, st, frame, target);
                } else {
                    if (w->window()) {
                        size = w->window()->constrainFrameSize(size);
                        target.setWidth(size.width());
                        target.setHeight(size.height());
                    }
                    st.parked = true;
                    st.awaitingCommit = true;
                    commitGeometry(w, frame, target);
                }
                y += size.height() + StashGapPx;
            }
        }
    }
    effects->addRepaintFull();
}

void SpacialDesktopEffect::updateDrag()
{
    EffectWindow *w = m_drag.window;
    if (!w) {
        return;
    }
    const RectF screen = w->screen()->geometryF();
    const QPointF cursor = effects->cursorPos();

    // Grab offset is kept constant in LOGICAL (warped) space, so the window
    // slides along the curve as it is dragged (Desktop5 semantics).
    const double uCursor = Warp::warpForward(Warp::xNorm(cursor.x(), screen.x(), screen.width()), m_warp);
    m_drag.centerXNorm = Warp::warpInverse(uCursor + m_drag.logicalOffset, m_warp);
    m_drag.scale = Warp::windowScale(m_drag.centerXNorm, m_warp);
}

void SpacialDesktopEffect::prePaintScreen(ScreenPrePaintData &data)
{
    if (m_drag.window || hasMiniatures()) {
        data.mask |= PAINT_SCREEN_WITH_TRANSFORMED_WINDOWS;
    }
    if (m_gridMode == GridDuringDrag && !m_gridTimeline.done()) {
        m_gridTimeline.advance(data.view);
    }
    if (!m_railTimeline.done()) {
        m_railTimeline.advance(data.view);
    }
    AnimationEffect::prePaintScreen(data);
}

void SpacialDesktopEffect::prePaintWindow(RenderView *view, EffectWindow *w, WindowPrePaintData &data)
{
    if (w == m_drag.window) {
        data.setTransformed();
    } else {
        auto it = m_windows.find(w);
        if (it != m_windows.end() && it->miniature) {
            data.setTransformed();
            it->miniTimeline.advance(view);
        }
    }
    AnimationEffect::prePaintWindow(view, w, data);
}

void SpacialDesktopEffect::paintWindow(const RenderTarget &renderTarget, const RenderViewport &viewport,
                                       EffectWindow *w, int mask, const Region &deviceRegion, WindowPaintData &data)
{
    if (w->isDesktop() && m_gridShader && m_gridMode != GridOff) {
        // Paint the wallpaper first, then the warped grid over it — under all
        // other windows, which paint later in the stacking order.
        AnimationEffect::paintWindow(renderTarget, viewport, w, mask, deviceRegion, data);
        const double opacity = (m_gridMode == GridAlways) ? 1.0 : m_gridTimeline.value();
        if (opacity > 0.0) {
            renderGrid(viewport, opacity);
        }
        return;
    }
    if (w == m_drag.window) {
        const auto it = m_windows.constFind(w);
        const RectF frame = w->frameGeometry();
        const QSizeF naturalSize = (it != m_windows.constEnd() && !it->naturalGeometry.isEmpty())
            ? it->naturalGeometry.size()
            : frame.size();

        // m_drag.scale is relative to the NATURAL size; the live buffer is the
        // current (possibly parked) frame, so convert to a paint factor.
        const double factor = (m_drag.scale * naturalSize.width()) / frame.width();
        const QSizeF paintedSize = frame.size() * factor;

        const RectF screen = w->screen()->geometryF();
        const QPointF cursor = effects->cursorPos();
        const double centerX = Warp::xPixel(m_drag.centerXNorm, screen.x(), screen.width());
        const double centerY = cursor.y() + (0.5 - m_drag.grabFrac.y()) * paintedSize.height();

        const QPointF topLeft(centerX - paintedSize.width() / 2.0,
                              centerY - paintedSize.height() / 2.0);

        data.setXScale(data.xScale() * factor);
        data.setYScale(data.yScale() * factor);
        data += (topLeft - frame.topLeft());

        m_drag.paintedRect = RectF(topLeft, paintedSize);

        // Drag rails: the horizontal grid-line indices behind the painted rect
        // at the window's x. The grid's y coordinate is yn / localScale, so
        // convert through the (unclamped) local scale at the window center.
        if (m_dragRails) {
            const double ls = 1.0 / Warp::warpForwardDeriv(m_drag.centerXNorm, m_warp);
            const double cY = screen.center().y();
            const double idxTop = (topLeft.y() - cY) / (ls * m_gridCellPx);
            const double idxBottom = (topLeft.y() + paintedSize.height() - cY) / (ls * m_gridCellPx);
            m_railBand = QVector2D(float(idxTop), float(idxBottom));
        }
    } else {
        const auto it = m_windows.constFind(w);
        if (it != m_windows.constEnd() && it->miniature) {
            // Blend from the drag-release rect into the parked slot, then hold.
            const RectF cur = currentMiniRect(*it);
            const RectF frame = w->frameGeometry();
            const double factor = cur.width() / frame.width();
            data.setXScale(data.xScale() * factor);
            data.setYScale(data.yScale() * factor);
            data += (cur.topLeft() - frame.topLeft());
        }
    }
    AnimationEffect::paintWindow(renderTarget, viewport, w, mask, deviceRegion, data);
}

void SpacialDesktopEffect::postPaintScreen()
{
    for (auto it = m_windows.constBegin(); it != m_windows.constEnd(); ++it) {
        if (it->miniature && !it->miniTimeline.done()) {
            effects->addRepaint(miniaturePaintedExtents(it.key(), it->miniFrom)
                                    .united(miniaturePaintedExtents(it.key(), it->miniRect)));
        }
    }
    if (m_gridMode == GridDuringDrag && !m_gridTimeline.done()) {
        effects->addRepaintFull();
    }
    if (!m_railTimeline.done()) {
        effects->addRepaintFull();
    }
    AnimationEffect::postPaintScreen();
}

void SpacialDesktopEffect::renderGrid(const RenderViewport &viewport, double opacity)
{
    const Rect device = viewport.scaledRenderRect();

    GLVertexBuffer *vbo = GLVertexBuffer::streamingBuffer();
    vbo->reset();
    vbo->setAttribLayout(std::span(GLVertexBuffer::GLVertex2DLayout), sizeof(GLVertex2D));

    const auto map = vbo->map<GLVertex2D>(6);
    if (!map) {
        return;
    }
    const float x0 = device.x(), y0 = device.y();
    const float x1 = device.x() + device.width(), y1 = device.y() + device.height();
    const GLVertex2D quad[6] = {
        {{x0, y0}, {0.0f, 0.0f}},
        {{x1, y0}, {1.0f, 0.0f}},
        {{x0, y1}, {0.0f, 1.0f}},
        {{x0, y1}, {0.0f, 1.0f}},
        {{x1, y0}, {1.0f, 0.0f}},
        {{x1, y1}, {1.0f, 1.0f}},
    };
    std::copy(std::begin(quad), std::end(quad), map->begin());
    vbo->unmap();
    vbo->setVertexCount(6);

    ShaderBinder binder(m_gridShader.get());
    GLShader *shader = m_gridShader.get();
    shader->setUniform(GLShader::Mat4Uniform::ModelViewProjectionMatrix, viewport.projectionMatrix());
    shader->setUniform(m_gridUniforms.gridColor,
                       QVector4D(float(m_gridColor.redF()), float(m_gridColor.greenF()),
                                 float(m_gridColor.blueF()), 1.0f));
    shader->setUniform(m_gridUniforms.deadZone,
                       QVector2D(float(m_warp.deadZoneLeft), float(m_warp.deadZoneRight)));
    shader->setUniform(m_gridUniforms.power, float(m_warp.power));
    shader->setUniform(m_gridUniforms.strength, float(m_warp.strength));
    shader->setUniform(m_gridUniforms.halfCellsX, float(viewport.renderRect().width() / 2.0 / m_gridCellPx));
    shader->setUniform(m_gridUniforms.halfCellsY, float(viewport.renderRect().height() / 2.0 / m_gridCellPx));
    shader->setUniform(m_gridUniforms.corePx, GridCorePx);
    shader->setUniform(m_gridUniforms.glowPx, GridGlowPx);
    shader->setUniform(m_gridUniforms.glowStrength, GridGlowStrength);
    shader->setUniform(m_gridUniforms.intensity, float(m_gridIntensity));
    shader->setUniform(m_gridUniforms.fadeStart, GridEdgeFadeStart);
    shader->setUniform(m_gridUniforms.fadeFloor, GridEdgeFadeFloor);
    shader->setUniform(m_gridUniforms.backdrop, float(m_gridBackdrop));
    shader->setUniform(m_gridUniforms.gridOpacity, float(opacity));
    const float dragActive = m_dragRails ? float(m_railTimeline.value()) : 0.0f;
    shader->setUniform(m_gridUniforms.dragActive, dragActive);
    shader->setUniform(m_gridUniforms.dragBand, QVector2D(m_railBand));
    shader->setUniform(m_gridUniforms.railGain, RailGain);
    shader->setUniform(m_gridUniforms.railThickness, RailThickness);

    glEnable(GL_BLEND);
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA); // premultiplied alpha
    vbo->render(GL_TRIANGLES);
    glDisable(GL_BLEND);
}

void SpacialDesktopEffect::slotWindowFinishUserMovedResized(EffectWindow *w)
{
    if (w != m_drag.window) {
        return;
    }

    if (m_gridMode == GridDuringDrag && m_gridTimeline.direction() != TimeLine::Backward) {
        m_gridTimeline.toggleDirection();
        effects->addRepaintFull();
    }
    if (m_railTimeline.direction() != TimeLine::Backward) {
        m_railTimeline.setDuration(RailFadeOut);
        m_railTimeline.toggleDirection();
        effects->addRepaintFull();
    }

    WindowState &st = m_windows[w];
    const RectF from = m_drag.paintedRect.isEmpty() ? w->frameGeometry() : m_drag.paintedRect;
    const double xn = m_drag.centerXNorm;
    const QPointF cursor = effects->cursorPos();
    const QPointF grabFrac = m_drag.grabFrac;
    const RectF startFrame = m_drag.startFrame;
    m_drag = DragState();

    // Esc-cancel: KWin restores the initial geometry, so a finish with the
    // frame back at its start position means the move was cancelled (or was a
    // no-op click) — leave everything as it is. A cancelled miniature grab-out
    // leaves the window unminimized at its natural geometry, which is a plain
    // un-parked window.
    if (w->frameGeometry() == startFrame) {
        if (st.parked && !st.miniature) {
            st.parked = false;
            st.column = -1;
        }
        effects->addRepaintFull();
        return;
    }

    const RectF screen = w->screen()->geometryF();
    const RectF workArea = effects->clientArea(PlacementArea, w);

    RectF target;
    if (Warp::flankDist(xn, m_warp) <= 0.0) {
        if (!st.parked) {
            // The window was never really resized — KWin's move loop already
            // put the real geometry where an unwarped move would (including
            // its own edge snapping). Nothing to commit.
            effects->addRepaintFull();
            return;
        }
        // Restore a parked window: natural size, grabbed point kept under the cursor.
        const QSizeF size = st.naturalGeometry.size();
        QPointF topLeft(cursor.x() - grabFrac.x() * size.width(),
                        cursor.y() - grabFrac.y() * size.height());
        target = RectF(topLeft, size);
        st.parked = false;
        st.column = -1;
    } else {
        // Park: snap to the nearest column on this side. Columns live at
        // fractions of the park zone, so they adapt to its size.
        const double side = (xn < 0) ? -1.0 : 1.0;
        const double innerX = std::abs(Warp::columnX(side, m_columnInner, m_warp));
        const double outerX = std::abs(Warp::columnX(side, m_columnOuter, m_warp));
        const double dInner = std::abs(std::abs(xn) - innerX);
        const double dOuter = std::abs(std::abs(xn) - outerX);
        st.column = (dInner <= dOuter) ? 0 : 1;

        const double colXNorm = side * ((dInner <= dOuter) ? innerX : outerX);
        const double sc = Warp::windowScale(colXNorm, m_warp);
        QSizeF size = st.naturalGeometry.size() * sc;
        if (!m_miniatureParking && w->window()) {
            // Real-resize mode has to respect client minimum sizes; a painted
            // miniature can be arbitrarily small.
            size = w->window()->constrainFrameSize(size);
        }
        const double centerX = Warp::xPixel(colXNorm, screen.x(), screen.width());
        target = RectF(QPointF(centerX - size.width() / 2.0, from.center().y() - size.height() / 2.0), size);

        if (m_miniatureParking) {
            RectF mini = target;
            if (mini.bottom() > workArea.bottom()) {
                mini.moveBottom(workArea.bottom());
            }
            if (mini.top() < workArea.top()) {
                mini.moveTop(workArea.top());
            }
            // Wide windows at the outer columns can poke past the screen edge
            // (visible as a cropped miniature) — keep them fully on-screen.
            if (mini.right() > workArea.right() - 4.0) {
                mini.moveRight(workArea.right() - 4.0);
            }
            if (mini.left() < workArea.left() + 4.0) {
                mini.moveLeft(workArea.left() + 4.0);
            }
            parkMiniature(w, st, from, mini);
            effects->addRepaintFull();
            return;
        }
        st.parked = true;
        st.awaitingCommit = true;
    }

    // Clamp into the work area.
    if (target.right() > workArea.right()) {
        target.moveRight(workArea.right());
    }
    if (target.bottom() > workArea.bottom()) {
        target.moveBottom(workArea.bottom());
    }
    if (target.left() < workArea.left()) {
        target.moveLeft(workArea.left());
    }
    if (target.top() < workArea.top()) {
        target.moveTop(workArea.top());
    }

    commitGeometry(w, from, target);
    effects->addRepaintFull();
}

void SpacialDesktopEffect::setMinimizedQuietly(EffectWindow *w, bool minimized)
{
    // Squash / Magic Lamp animate every minimizedChanged unless a fullscreen
    // effect is active. The signal fires synchronously inside setMinimized, so
    // claiming the fullscreen slot for just this call suppresses their
    // conflicting animation without touching anything else.
    if (!effects->activeFullScreenEffect()) {
        effects->setActiveFullScreenEffect(this);
        m_quietMinimize = true;
        w->setMinimized(minimized);
        m_quietMinimize = false;
        effects->setActiveFullScreenEffect(nullptr);
    } else {
        w->setMinimized(minimized);
    }
}

void SpacialDesktopEffect::parkMiniature(EffectWindow *w, WindowState &st, const RectF &from, const RectF &target)
{
    st.parked = true;
    st.miniature = true;
    st.miniRect = target;
    st.miniFrom = m_animate ? from : target;
    st.miniTimeline = TimeLine(m_duration, TimeLine::Forward);
    st.miniTimeline.setEasingCurve(QEasingCurve::OutCubic);
    if (!m_animate) {
        st.miniTimeline.setElapsed(m_duration);
    }

    // The visible-ref keeps the window's item painted while minimized — which
    // also keeps the client unsuspended, so the miniature stays live.
    st.visibleRef = EffectWindowVisibleRef(w, EffectWindow::PAINT_DISABLED_BY_MINIMIZE);
    setMinimizedQuietly(w, true);

    // KWin's move loop dragged the real (invisible) geometry into the flank;
    // put it back so any unminimize restores to the pre-drag position. Same
    // size, so the client never re-layouts.
    if (w->window()) {
        w->window()->moveResize(st.naturalGeometry);
    }
}

void SpacialDesktopEffect::unparkMiniature(EffectWindow *w, WindowState &st)
{
    const RectF from = st.miniRect;
    const RectF to = w->frameGeometry(); // untouched natural geometry
    st.parked = false;
    st.miniature = false;
    st.column = -1;
    st.visibleRef = EffectWindowVisibleRef();

    // On an external unminimize (taskbar, alt-tab) with Squash or Magic Lamp
    // active, their unminimize animation is already playing — adding ours on
    // top would double-transform the window.
    const bool otherAnimation = !m_quietMinimize
        && (effects->isEffectLoaded(QStringLiteral("squash"))
            || effects->isEffectLoaded(QStringLiteral("magiclamp")));

    if (m_animate && !otherAnimation) {
        animate(w, Size, 0, m_duration, FPx2(to.width(), to.height()),
                QEasingCurve(QEasingCurve::OutCubic), 0, FPx2(from.width(), from.height()));
        animate(w, Translation, 0, m_duration, FPx2(0.0, 0.0), QEasingCurve(QEasingCurve::OutCubic), 0,
                FPx2(from.center().x() - to.center().x(), from.center().y() - to.center().y()));
    }
    effects->addRepaintFull();
}

void SpacialDesktopEffect::commitGeometry(EffectWindow *w, const RectF &from, const RectF &to)
{
    Window *window = w->window();
    if (!window) {
        return;
    }

    // CrossFadePrevious snapshots the old content when the animation starts, so
    // it must be scheduled before the real geometry change. Skip it when wobbly
    // windows is loaded — both effects redirect the window in the drawWindow
    // chain and the loser's snapshot silently vanishes.
    const bool crossFade = m_animate && !effects->isEffectLoaded(QStringLiteral("wobblywindows"));
    if (crossFade) {
        animate(w, CrossFadePrevious, 0, m_duration, FPx2(1.0), QEasingCurve(QEasingCurve::OutCubic), 0, FPx2(0.0));
    }

    window->moveResize(to);

    if (m_animate) {
        animate(w, Size, 0, m_duration, FPx2(to.width(), to.height()),
                QEasingCurve(QEasingCurve::OutCubic), 0, FPx2(from.width(), from.height()));
        // Size anchors about the center, so the translation compensates for the
        // center shift between the painted drag rect and the committed rect.
        animate(w, Translation, 0, m_duration, FPx2(0.0, 0.0), QEasingCurve(QEasingCurve::OutCubic), 0,
                FPx2(from.center().x() - to.center().x(), from.center().y() - to.center().y()));
    }
}

void SpacialDesktopEffect::slotWindowFrameGeometryChanged(EffectWindow *w, const RectF &oldGeometry)
{
    const auto it = m_windows.find(w);
    if (it == m_windows.end()) {
        return;
    }
    if (it->awaitingCommit) {
        // Adopt whatever the client actually committed (it may have refused a
        // sub-minimum size) so restore/re-drag bookkeeping never desyncs.
        it->awaitingCommit = false;
        return;
    }
    if (it->parked && w != m_drag.window
        && w->frameGeometry().size() != oldGeometry.size()) {
        // Someone else (client or user) resized a parked window — it owns its
        // geometry again.
        m_windows.erase(it);
    }
}

} // namespace KWin
