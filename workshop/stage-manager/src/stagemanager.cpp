/**
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#include "stagemanager.h"
#include "gridshader.h"
#include "shortcuts.h"
#include "stagemanagerconfig.h"

#include "core/colorspace.h"
#include "core/output.h"
#include "core/rendertarget.h"
#include "core/renderviewport.h"
#include "effect/effecthandler.h"
#include "effect/effectwindow.h"
#include "opengl/glframebuffer.h"
#include "opengl/glshader.h"
#include "opengl/glshadermanager.h"
#include "opengl/gltexture.h"
#include "opengl/glvertexbuffer.h"
#include "options.h"
#include "scene/itemgeometry.h"
#include "window.h"

#include <KGlobalAccel>
#include <KLocalizedString>

#include <QAction>
#include <QDBusConnection>
#include <QEasingCurve>
#include <QLineF>
#include <QTimer>
#include <QVector4D>

#include <epoxy/gl.h>

#include <cmath>

namespace
{
constexpr double DragThresholdPx = 8.0;

/**
 * Perspective camera distance for tilted miniatures, as a multiple of the
 * miniature's larger side. Smaller = stronger foreshortening.
 */
constexpr double PerspectiveDistanceFactor = 2.5;

// Grid look dials from Desktop5's config.js (venue-tuned there; constants here).
constexpr float GridCorePx = 1.5f;
constexpr float GridGlowPx = 6.0f;
constexpr float GridGlowStrength = 0.5f;
constexpr float GridEdgeFadeStart = 0.65f;
constexpr float GridEdgeFadeFloor = 0.35f;
constexpr std::chrono::milliseconds GridFadeDuration{200};

// Shake-to-stash dials from Desktop5's config.js.
constexpr double ShakeMinTravel = 20.0;
constexpr std::chrono::milliseconds ShakeWindow{500};
constexpr int ShakeCount = 4;
constexpr double StashGapPx = 24.0;

// Drag rails dials from Desktop5's config.js.
constexpr float RailGain = 1.6f;
constexpr float RailThickness = 2.2f;
constexpr std::chrono::milliseconds RailFadeIn{150};
constexpr std::chrono::milliseconds RailFadeOut{250};
}

namespace KWin
{

StageManagerEffect::StageManagerEffect()
{
    StageManagerConfig::instance(effects->config());
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

    connect(
        effects,
        &EffectsHandler::windowAdded,
        this,
        &StageManagerEffect::slotWindowAdded
    );
    connect(
        effects,
        &EffectsHandler::windowDeleted,
        this,
        &StageManagerEffect::slotWindowDeleted
    );
    connect(
        effects,
        &EffectsHandler::windowActivated,
        this,
        &StageManagerEffect::slotWindowActivated
    );
    connect(
        effects,
        &EffectsHandler::mouseChanged,
        this,
        &StageManagerEffect::slotMouseChanged
    );
    connect(effects, &EffectsHandler::virtualScreenGeometryChanged, this, [this]() {
        /**
         * Output layout changed under us: abort any drag; parked windows are
         * real geometry, KWin's own output handling relocates them.
         */
        m_drag = DragState();
    });

    const auto windows = effects->stackingOrder();
    for (EffectWindow *w : windows) {
        slotWindowAdded(w);
    }

    QDBusConnection::sessionBus().registerObject(
        QStringLiteral("/org/kde/KWin/Effect/StageManager1"),
        QStringLiteral("org.kde.KWin.Effect.StageManager1"),
        this,
        QDBusConnection::ExportScriptableSlots
    );

    setupShortcuts();
}

void StageManagerEffect::setupShortcuts()
{
    /**
     * Global shortcuts live in the "kwin" KGlobalAccel component (this runs
     * inside kwin_wayland), so they show up under System Settings → Shortcuts
     * → KWin and in the effect's own KCM. Object names are the config keys.
     */
    using namespace StageManagerShortcuts;

    const std::array<void (StageManagerEffect::*)(), Actions.size()> handlers = {
        &StageManagerEffect::stageActiveWindowAlone,
        &StageManagerEffect::stash,
        &StageManagerEffect::restoreAll,
        &StageManagerEffect::stageActiveWindow,
        &StageManagerEffect::nextGroup,
        &StageManagerEffect::previousGroup,
    };

    for (size_t i = 0; i < Actions.size(); ++i) {
        QAction *action = new QAction(this);
        action->setObjectName(QString::fromLatin1(Actions[i].objectName));
        action->setText(i18n(Actions[i].text));
        KGlobalAccel::self()->setGlobalShortcut(action, Actions[i].defaultShortcut);
        connect(action, &QAction::triggered, this, handlers[i]);
    }
}

StageManagerEffect::~StageManagerEffect()
{
    QDBusConnection::sessionBus()
        .unregisterObject(QStringLiteral("/org/kde/KWin/Effect/StageManager1"));

    /**
     * Don't leave windows stranded as minimized miniatures when the effect is
     * unloaded — hand them back as regular unminimized windows at their natural
     * geometry (the real frame is parked at the slot while miniature).
     */
    for (auto it = m_windows.begin(); it != m_windows.end(); ++it) {
        releaseMiniatureTexture(*it);
        if (it->miniature) {
            it->visibleRef = EffectWindowVisibleRef();
            it.key()->elevate(false);
            it.key()->setMinimized(false);
        }
    }
}

bool StageManagerEffect::supported()
{
    return effects->animationsSupported();
}

void StageManagerEffect::reconfigure(ReconfigureFlags)
{
    StageManagerConfig::self()->read();
    const double dz = StageManagerConfig::warpDeadZone();
    m_warp.deadZoneLeft = StageManagerConfig::parkLeft() ? dz : 1.0;
    m_warp.deadZoneRight = StageManagerConfig::parkRight() ? dz : 1.0;
    m_warp.power = StageManagerConfig::warpPower();
    m_warp.strength = StageManagerConfig::warpStrength();
    m_warp.minScale = StageManagerConfig::minScale();
    m_columnInner = StageManagerConfig::columnInner();
    m_columnOuter = StageManagerConfig::columnOuter();
    m_animate = StageManagerConfig::animationsEnabled();
    m_miniatureParking = StageManagerConfig::miniatureParking();
    m_duration = Effect::animationTime(
        std::chrono::milliseconds(StageManagerConfig::animationDuration())
    );
    m_gridMode = StageManagerConfig::gridMode();
    m_gridColor = StageManagerConfig::gridColor();
    m_gridCellPx = StageManagerConfig::gridCellSize();
    m_gridIntensity = StageManagerConfig::gridIntensity();
    m_gridBackdrop = StageManagerConfig::gridBackdrop();
    m_shakeToStash = StageManagerConfig::shakeToStash();
    m_dragRails = StageManagerConfig::dragRails();
    m_stageMode = StageManagerConfig::stageMode();
    if (m_stageMode) {
        // The stage strip is built on live miniatures.
        m_miniatureParking = true;
    }
    m_stageTilt = StageManagerConfig::miniatureTilt();
    m_stageMiniWidth = StageManagerConfig::stageMiniatureWidth();
    m_stageMiniHeight = StageManagerConfig::stageMiniatureHeight();

    // Re-apply the tilt/size dials to whatever is parked right now.
    for (auto it = m_windows.begin(); it != m_windows.end(); ++it) {
        if (it->miniature && stripGroupIndexOf(it.key()) < 0) {
            it->tiltFrom = currentTilt(*it);
            it->tiltTo = tiltSign(it->miniRect, it.key()) * m_stageTilt;
            it->miniFrom = currentMiniRect(*it);
            it->miniTimeline = TimeLine(m_duration, TimeLine::Forward);
            it->miniTimeline.setEasingCurve(QEasingCurve::OutCubic);
        }
    }
    if (!m_strip.isEmpty()) {
        relayoutStrip();
    }
    effects->addRepaintFull();
}

bool StageManagerEffect::isActive() const
{
    const bool gridActive = m_gridShader
        && (m_gridMode == GridAlways || (
                m_gridMode == GridDuringDrag
                && (m_drag.window || !m_gridTimeline.done())
            )
        );

    return AnimationEffect::isActive()
        || m_drag.window
        || hasMiniatures()
        || gridActive;
}

bool StageManagerEffect::hasMiniatures() const
{
    for (const WindowState &st : m_windows) {
        if (st.miniature) {
            return true;
        }
    }

    return false;
}

int StageManagerEffect::requestedEffectChainPosition() const
{
    return 50;
}

bool StageManagerEffect::isRelevant(EffectWindow *w) const
{
    /**
     * keepBelow / skipTaskbar exclude pinned desktop companions (system
     * monitors, wallpaper/status overlays): they stay fixed beneath the
     * managed windows rather than being parked.
     */
    return w && w->isNormalWindow() && w->isMovable() && !w->isSpecialWindow()
        && !w->isFullScreen() && !w->isDeleted() && w->screen()
        && !w->keepBelow()
        && w->window() && !w->window()->skipTaskbar()
        && w->window()->maximizeMode() == MaximizeRestore;
}

void StageManagerEffect::slotWindowAdded(EffectWindow *w)
{
    connect(w, &EffectWindow::windowStartUserMovedResized,
            this, &StageManagerEffect::slotWindowStartUserMovedResized);
    connect(w, &EffectWindow::windowStepUserMovedResized,
            this, &StageManagerEffect::slotWindowStepUserMovedResized);
    connect(w, &EffectWindow::windowFinishUserMovedResized,
            this, &StageManagerEffect::slotWindowFinishUserMovedResized);
    connect(w, &EffectWindow::windowFrameGeometryChanged,
            this, &StageManagerEffect::slotWindowFrameGeometryChanged);
    connect(w, &EffectWindow::windowDamaged,
            this, &StageManagerEffect::slotWindowDamaged);
    connect(w, &EffectWindow::windowOpacityChanged, this, [this, w]() {
        slotWindowDamaged(w); // opacity is baked into the offscreen copy
    });
    connect(w, &EffectWindow::minimizedChanged,
            this, &StageManagerEffect::slotMinimizedChanged);
}

RectF StageManagerEffect::currentMiniRect(const WindowState &st)
{
    const double t = st.miniTimeline.value();
    const RectF &a = st.miniFrom;
    const RectF &b = st.miniRect;
    return RectF(a.x() + (b.x() - a.x()) * t,
                 a.y() + (b.y() - a.y()) * t,
                 a.width() + (b.width() - a.width()) * t,
                 a.height() + (b.height() - a.height()) * t);
}

RectF StageManagerEffect::miniaturePaintedExtents(
    EffectWindow *w,
    const RectF &paintedFrameRect
) {
    /**
     * The painted footprint exceeds the frame rect: the shadow and decoration
     * (expandedGeometry) scale along with it, and the scaled rect has
     * fractional right/bottom edges that must not round out of the repaint
     * region — both otherwise show up as a clipped-looking miniature.
     */
    const RectF frame = w->frameGeometry();
    const RectF expanded = w->expandedGeometry();
    const double factor = paintedFrameRect.width() / frame.width();

    return RectF(paintedFrameRect.x() + (expanded.x() - frame.x()) * factor,
                 paintedFrameRect.y() + (expanded.y() - frame.y()) * factor,
                 expanded.width() * factor,
                 expanded.height() * factor)
        .adjusted(-2.0, -2.0, 2.0, 2.0);
}

double StageManagerEffect::currentTilt(const WindowState &st)
{
    const double t = st.miniTimeline.value();
    return st.tiltFrom + (st.tiltTo - st.tiltFrom) * t;
}

double StageManagerEffect::tiltSign(const RectF &rect, EffectWindow *w) const
{
    /**
     * The inner edge (toward the screen center) comes forward, the outer edge
     * recedes — a right-hand strip tilts like a page opening toward the
     * middle of the screen, a left-hand one mirrors that.
     */
    const RectF screen = w->screen()->geometryF();
    return (rect.center().x() >= screen.center().x()) ? 1.0 : -1.0;
}

double StageManagerEffect::stripScaleFor(
    const WindowState &st,
    EffectWindow *ref,
    double warpScale
) const {
    /**
     * Fit every miniature into the configured box (fractions of the screen);
     * the warp scale at the strip is the ceiling so small windows never
     * appear nearly full size.
     */
    const RectF screen = ref->screen()->geometryF();
    const QSizeF natural = st.naturalGeometry.size();
    double s = warpScale;
    if (natural.width() > 0.0) {
        s = std::min(s, m_stageMiniWidth * screen.width() / natural.width());
    }

    if (natural.height() > 0.0) {
        s = std::min(s, m_stageMiniHeight * screen.height() / natural.height());
    }

    return std::max(s, 0.02);
}

QMatrix4x4 StageManagerEffect::miniatureMatrix(
    const RectF &frameRect,
    const QPointF &originOffset,
    double frameScale,
    double tiltDeg,
    double devScale
) {
    /**
     * Device-pixel model matrix mapping texture-local points (origin at the
     * texture's top-left, which sits `originOffset` from the frame's top-left
     * in logical space) to the screen: the frame lands on `frameRect` scaled
     * by `frameScale`, then the whole miniature is rotated about its vertical
     * center line and projected with a simple pinhole perspective (w = 1 - z/d,
     * so +z comes toward the viewer). The z output row is zeroed so the ortho
     * projection's depth range never clips; GL divides by w and interpolates
     * the texture coordinates perspective-correctly.
     */
    QMatrix4x4 m;
    m.translate(float(frameRect.x() * devScale), float(frameRect.y() * devScale));

    if (std::abs(tiltDeg) > 0.01) {
        const float cx = float(frameRect.width() * devScale / 2.0);
        const float cy = float(frameRect.height() * devScale / 2.0);
        const float d = float(
            PerspectiveDistanceFactor
            * std::max(frameRect.width(), frameRect.height())
            * devScale
        );
        const QMatrix4x4 persp(
            1.0f, 0.0f, 0.0f, 0.0f,
            0.0f, 1.0f, 0.0f, 0.0f,
            0.0f, 0.0f, 0.0f, 0.0f,
            0.0f, 0.0f, -1.0f / d, 1.0f
        );

        m.translate(cx, cy);
        m *= persp;
        m.rotate(float(tiltDeg), 0.0f, 1.0f, 0.0f);
        m.translate(-cx, -cy);
    }

    m.scale(float(frameScale));
    m.translate(
        float(originOffset.x() * devScale),
        float(originOffset.y() * devScale)
    );

    return m;
}

std::array<QPointF, 4> StageManagerEffect::projectQuad(
    const QMatrix4x4 &m,
    const RectF &localRect,
    double devScale
) {
    // localRect is in texture-local device pixels; the result is logical.
    const std::array<QPointF, 4> corners = {
        QPointF(localRect.left(), localRect.top()),
        QPointF(localRect.right(), localRect.top()),
        QPointF(localRect.right(), localRect.bottom()),
        QPointF(localRect.left(), localRect.bottom()),
    };

    std::array<QPointF, 4> out;
    for (size_t i = 0; i < corners.size(); ++i) {
        const QVector4D v = m * QVector4D(float(corners[i].x()), float(corners[i].y()), 0.0f, 1.0f);
        const double w = (std::abs(v.w()) > 1e-6) ? v.w() : 1.0;

        out[i] = QPointF(v.x() / w / devScale, v.y() / w / devScale);
    }

    return out;
}

RectF StageManagerEffect::quadBounds(const std::array<QPointF, 4> &quad)
{
    double l = quad[0].x(), r = quad[0].x(), t = quad[0].y(), b = quad[0].y();
    for (const QPointF &p : quad) {
        l = std::min(l, p.x());
        r = std::max(r, p.x());
        t = std::min(t, p.y());
        b = std::max(b, p.y());
    }

    return RectF(l, t, r - l, b - t);
}

bool StageManagerEffect::quadContains(
    const std::array<QPointF, 4> &quad,
    const QPointF &p
) {
    // Convex quad: the point must be on the same side of all four edges.
    int sign = 0;
    for (size_t i = 0; i < quad.size(); ++i) {
        const QPointF &a = quad[i];
        const QPointF &b = quad[(i + 1) % quad.size()];
        const double cross = (b.x() - a.x())
            * (p.y() - a.y())
            - (b.y() - a.y())
            * (p.x() - a.x());
        const int s = (cross > 0.0) ? 1 : ((cross < 0.0) ? -1 : 0);
        if (s == 0) {
            continue;
        }

        if (sign == 0) {
            sign = s;
        } else if (s != sign) {
            return false;
        }
    }

    return true;
}

std::array<QPointF, 4> StageManagerEffect::miniatureFrameQuad(
    EffectWindow *w,
    const WindowState &st
) const {
    const double devScale = w->screen()->scale();
    const RectF frame = w->frameGeometry();
    const RectF cur = currentMiniRect(st);
    const double frameScale = cur.width() / frame.width();
    const QMatrix4x4 m = miniatureMatrix(
        cur,
        QPointF(0.0, 0.0),
        frameScale,
        currentTilt(st),
        devScale
    );

    return projectQuad(
        m,
        RectF(0.0, 0.0, frame.width() * devScale, frame.height() * devScale),
        devScale
    );
}

RectF StageManagerEffect::miniatureExtents(EffectWindow *w, const WindowState &st) const
{
    /**
     * Screen footprint of the tilted miniature including its shadow and
     * decoration (expandedGeometry), plus a safety margin for fractional
     * edges.
     */
    const double devScale = w->screen()->scale();
    const RectF frame = w->frameGeometry();
    const RectF expanded = w->expandedGeometry();
    const RectF cur = currentMiniRect(st);
    const double frameScale = cur.width() / frame.width();
    const QPointF originOffset = expanded.topLeft() - frame.topLeft();
    const QMatrix4x4 m = miniatureMatrix(
        cur,
        originOffset,
        frameScale,
        currentTilt(st),
        devScale
    );
    const auto quad = projectQuad(
        m,
        RectF(0.0, 0.0, expanded.width() * devScale, expanded.height() * devScale),
        devScale
    );

    return quadBounds(quad).adjusted(-2.0, -2.0, 2.0, 2.0);
}

RectF StageManagerEffect::tiltedBounds(const RectF &frameRect, double tiltDeg) const
{
    // Logical bounding box of a frame rect once tilted in place.
    const QMatrix4x4 m = miniatureMatrix(frameRect, QPointF(0.0, 0.0), 1.0, tiltDeg, 1.0);

    return quadBounds(
        projectQuad(m, RectF(0.0, 0.0, frameRect.width(), frameRect.height()), 1.0)
    );
}

void StageManagerEffect::clampTiltedIntoArea(
    RectF &rect,
    double tiltDeg.
    const RectF &area
) const {
    // Shift `rect` so its projected (tilted) footprint stays inside `area`.
    constexpr double Pad = 4.0;
    RectF b = tiltedBounds(rect, tiltDeg);
    if (b.right() > area.right() - Pad) {
        rect.moveLeft(rect.left() - (b.right() - (area.right() - Pad)));
        b = tiltedBounds(rect, tiltDeg);
    }

    if (b.left() < area.left() + Pad) {
        rect.moveLeft(rect.left() + ((area.left() + Pad) - b.left()));
        b = tiltedBounds(rect, tiltDeg);
    }

    if (b.bottom() > area.bottom() - Pad) {
        rect.moveTop(rect.top() - (b.bottom() - (area.bottom() - Pad)));
        b = tiltedBounds(rect, tiltDeg);
    }

    if (b.top() < area.top() + Pad) {
        rect.moveTop(rect.top() + ((area.top() + Pad) - b.top()));
    }
}

void StageManagerEffect::releaseMiniatureTexture(WindowState &st)
{
    if (!st.texture && !st.fbo) {
        return;
    }

    effects->makeOpenGLContextCurrent();
    st.fbo.reset();
    st.texture.reset();
    st.textureDirty = true;
}

void StageManagerEffect::updateMiniatureTexture(EffectWindow *w, WindowState &st)
{
    /**
     * Keep an offscreen, mipmapped copy of the window (expanded geometry:
     * frame + decoration + shadow) up to date. Rendering through
     * EffectsHandler::renderWindow bypasses the effect chain, and with a
     * viewport matching the window's own geometry the item renderer's clipping
     * is exact, so the copy is complete regardless of where the miniature is
     * shown.
     */
    const double devScale = w->screen()->scale();
    const RectF expanded = w->expandedGeometry();
    const auto snap = [devScale](double v) {
        return std::round(v * devScale) / devScale;
    };
    const double x0 = snap(expanded.left()), y0 = snap(expanded.top());
    const double x1 = snap(expanded.right()), y1 = snap(expanded.bottom());
    const RectF logical(x0, y0, x1 - x0, y1 - y0);
    const QSize texSize(
        int(std::lround(logical.width() * devScale)),
        int(std::lround(logical.height() * devScale))
    );

    if (texSize.isEmpty()) {
        releaseMiniatureTexture(st);

        return;
    }

    if (!st.texture || st.texture->size() != texSize) {
        st.fbo.reset();
        st.texture.reset();

        const int levels = 1 + int(
            std::floor(std::log2(std::max(texSize.width(), texSize.height())))
        );
        st.texture = GLTexture::allocate(GL_RGBA8, texSize, std::max(levels, 1));
        if (!st.texture) {
            return;
        }

        st.texture->setFilter(GL_LINEAR_MIPMAP_LINEAR);
        st.texture->setWrapMode(GL_CLAMP_TO_EDGE);
        st.fbo = std::make_shared<GLFramebuffer>(st.texture.get());
        if (!st.fbo->valid()) {
            st.fbo.reset();
            st.texture.reset();

            return;
        }

        st.textureDirty = true;
    }

    if (!st.textureDirty) {
        return;
    }

    RenderTarget renderTarget(st.fbo.get());
    RenderViewport viewport(logical, devScale, renderTarget, QPoint());

    GLFramebuffer::pushFramebuffer(st.fbo.get());
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    glClear(GL_COLOR_BUFFER_BIT);

    WindowPaintData data;
    data.setOpacity(1.0);
    effects->renderWindow(
        renderTarget,
        viewport,
        w,
        PAINT_WINDOW_TRANSFORMED | PAINT_WINDOW_TRANSLUCENT,
        Region::infinite(),
        data
    );

    GLFramebuffer::popFramebuffer();

    st.texture->bind();
    st.texture->generateMipmaps();
    st.texture->unbind();

    st.textureRect = logical;
    st.textureDirty = false;
}

bool StageManagerEffect::paintMiniature(
    const RenderTarget &renderTarget,
    const RenderViewport &viewport,
    EffectWindow *w,
    WindowState &st,
    const Region &deviceRegion,
    const WindowPaintData &data
) {
    if (!st.texture) {
        return false;
    }

    const double devScale = viewport.scale();
    const RectF frame = w->frameGeometry();
    const RectF cur = currentMiniRect(st);
    const double frameScale = cur.width() / frame.width();
    const QPointF originOffset = st.textureRect.topLeft() - frame.topLeft();
    const QMatrix4x4 model = miniatureMatrix(
        cur,
        originOffset,
        frameScale,
        currentTilt(st),
        devScale
    );

    GLShader *shader = ShaderManager::instance()->shader(
        ShaderTrait::MapTexture
        | ShaderTrait::Modulate
        | ShaderTrait::AdjustSaturation
        | ShaderTrait::TransformColorspace
    );
    ShaderBinder binder(shader);

    const double texW = st.texture->width();
    const double texH = st.texture->height();
    WindowQuad quad;
    quad[0] = WindowVertex(QPointF(0.0, 0.0), QPointF(0.0, 0.0));
    quad[1] = WindowVertex(QPointF(texW, 0.0), QPointF(1.0, 0.0));
    quad[2] = WindowVertex(QPointF(texW, texH), QPointF(1.0, 1.0));
    quad[3] = WindowVertex(QPointF(0.0, texH), QPointF(0.0, 1.0));

    RenderGeometry geometry;
    geometry.appendWindowQuad(quad, 1.0); // positions already in device pixels
    geometry.postProcessTextureCoordinates(st.texture->matrix(NormalizedCoordinates));

    GLVertexBuffer *vbo = GLVertexBuffer::streamingBuffer();
    vbo->reset();
    vbo->setAttribLayout(
        std::span(GLVertexBuffer::GLVertex2DLayout),
        sizeof(GLVertex2D)
    );
    const auto map = vbo->map<GLVertex2D>(geometry.size());
    if (!map) {
        return false;
    }
    geometry.copy(*map);
    vbo->unmap();
    vbo->bindArrays();

    const qreal rgb = data.brightness() * data.opacity();
    const qreal a = data.opacity();
    const auto toXYZ = renderTarget.colorDescription()->containerColorimetry().toXYZ();

    shader->setUniform(
        GLShader::Mat4Uniform::ModelViewProjectionMatrix,
        viewport.projectionMatrix() * model
    );
    shader->setUniform(
        GLShader::Vec4Uniform::ModulationConstant,
        QVector4D(rgb, rgb, rgb, a)
    );
    shader->setUniform(
        GLShader::FloatUniform::Saturation,
        data.saturation()
    );
    shader->setUniform(
        GLShader::Vec3Uniform::PrimaryBrightness,
        QVector3D(toXYZ(1, 0), toXYZ(1, 1), toXYZ(1, 2))
    );
    shader->setUniform(
        GLShader::IntUniform::TextureWidth,
        st.texture->width()
    );
    shader->setUniform(
        GLShader::IntUniform::TextureHeight,
        st.texture->height()
    );
    shader->setColorspaceUniforms(
        ColorDescription::sRGB,
        renderTarget.colorDescription(), RenderingIntent::Perceptual
    );

    // Damage-only frames hand us a finite region: scissor to it like the renderer would.
    const bool clipping = deviceRegion != Region::infinite();
    const Region clipRegion = clipping
        ? viewport.transform().map(deviceRegion, renderTarget.transformedSize())
        : Region::infinite();

    if (clipping) {
        glEnable(GL_SCISSOR_TEST);
    }

    glEnable(GL_BLEND);
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA); // premultiplied alpha

    st.texture->bind();
    vbo->draw(clipRegion, GL_TRIANGLES, 0, geometry.count(), clipping);
    st.texture->unbind();

    glDisable(GL_BLEND);
    if (clipping) {
        glDisable(GL_SCISSOR_TEST);
    }
    vbo->unbindArrays();

    return true;
}

void StageManagerEffect::slotWindowDamaged(EffectWindow *w)
{
    const auto it = m_windows.find(w);
    if (it != m_windows.end() && it->miniature) {
        it->textureDirty = true;
        effects->addRepaint(miniatureExtents(w, *it));
    }
}

void StageManagerEffect::slotMinimizedChanged(EffectWindow *w)
{
    /**
     * Any unminimize — our click-to-restore, the taskbar, alt-tab — restores a
     * miniature-parked window to its untouched natural geometry.
     */
    const auto it = m_windows.find(w);
    if (it != m_windows.end() && it->miniature && !w->isMinimized()) {
        if (m_unparkByDrag) {
            /**
             * Grab-out: stop painting the miniature but keep `parked` set so
             * the drag's finish handler goes through the restore/re-park
             * branches instead of the plain-move early return.
             */
            it->miniature = false;
            it->tiltFrom = 0.0;
            it->tiltTo = 0.0;
            it->visibleRef = EffectWindowVisibleRef();
            releaseMiniatureTexture(*it);
            w->elevate(false);
        } else if (m_stageMode && !m_swapping && stripGroupIndexOf(w) >= 0) {
            /**
             * External restore (alt-tab, taskbar) of a pile member: bring its
             * whole stage over, not just this window. The window itself is
             * already unminimized; the swap is deferred a tick so the task
             * switcher has fully closed before everything reshuffles.
             */
            unparkMiniature(w, *it);
            QTimer::singleShot(0, this, [this, w]() {
                if (m_windows.contains(w) && stripGroupIndexOf(w) >= 0) {
                    swapToWindowGroup(w);
                }
            });
        } else {
            unparkMiniature(w, *it);
            removeFromStrip(w);
        }
    }
}

void StageManagerEffect::slotMouseChanged(
    const QPointF &pos,
    const QPointF &oldpos,
    Qt::MouseButtons buttons,
    Qt::MouseButtons oldbuttons,
    Qt::KeyboardModifiers modifiers,
    Qt::KeyboardModifiers oldmodifiers
) {
    Q_UNUSED(oldpos)
    Q_UNUSED(modifiers)
    Q_UNUSED(oldmodifiers)

    /**
     * Input hit-testing ignores miniatures (the real window is minimized), so
     * this passive observation is their interaction channel. A press inside a
     * miniature arms a pending grab: releasing within the drag threshold is a
     * click (restore to natural geometry), moving beyond it re-grabs the window
     * into a real drag along the warp curve.
     */
    if (m_pendingGrab.window) {
        EffectWindow *w = m_pendingGrab.window;
        const auto it = m_windows.constFind(w);
        if (it == m_windows.constEnd() || !it->miniature) {
            m_pendingGrab = PendingGrab();
        } else if (!(buttons & Qt::LeftButton)) {
            m_pendingGrab = PendingGrab();
            if (m_stageMode) {
                // Click on a pile = swap it with the current stage.
                swapToWindowGroup(w);
            } else {
                setMinimizedQuietly(w, false); // slotMinimizedChanged does the rest.
                effects->activateWindow(w);
            }

            return;
        } else if (QLineF(m_pendingGrab.pressPos, pos).length() > DragThresholdPx) {
            beginMiniatureDrag(w, pos);

            return;
        } else {
            return; // holding still within the threshold.
        }
    }

    if (!(buttons & Qt::LeftButton) || (oldbuttons & Qt::LeftButton)) {
        return;
    }

    /**
     * Resolve overlaps in paint order: every miniature is elevated when parked
     * and KWin paints elevated items in elevation order, so the most recently
     * parked one is on top (front of a pile, cascade offset 0).
     */
    QList<EffectWindow *> candidates;
    for (auto it = m_windows.constBegin(); it != m_windows.constEnd(); ++it) {
        if (it->miniature) {
            candidates.append(it.key());
        }
    }

    std::sort(
        candidates.begin(),
        candidates.end(),
        [this](EffectWindow *a, EffectWindow *b) {
            return m_windows[a].parkSerial > m_windows[b].parkSerial;
        }
    );

    for (EffectWindow *w : std::as_const(candidates)) {
        const auto st = m_windows.constFind(w);
        if (st != m_windows.constEnd() && st->miniature
            && quadContains(miniatureFrameQuad(w, *st), pos)) {
            m_pendingGrab.window = w;
            m_pendingGrab.pressPos = pos;
            m_pendingGrab.grabFrac = QPointF(
                std::clamp((pos.x() - st->miniRect.x()) / st->miniRect.width(), 0.0, 1.0),
                std::clamp((pos.y() - st->miniRect.y()) / st->miniRect.height(), 0.0, 1.0)
            );

            return;
        }
    }
}

void StageManagerEffect::beginMiniatureDrag(
    EffectWindow *w,
    const QPointF &cursorPos
) {
    const auto it = m_windows.constFind(w);
    const RectF mini = it->miniRect;
    const QPointF grabFrac = m_pendingGrab.grabFrac;
    m_pendingGrab = PendingGrab();

    /**
     * Unminimize without the restore animation; `parked` stays set (see
     * slotMinimizedChanged) so the finish handler restores or re-parks.
     */
    m_unparkByDrag = true;
    setMinimizedQuietly(w, false);
    m_unparkByDrag = false;
    removeFromStrip(w);

    /**
     * Seed the drag with the miniature's geometry instead of the (full-size,
     * centrally-located) real frame, so the painted window starts exactly where
     * the miniature was and slides out along the curve.
     */
    const RectF screen = w->screen()->geometryF();
    m_dragOverride.window = w;
    m_dragOverride.grabFrac = grabFrac;
    m_dragOverride.logicalOffset =
        Warp::warpForward(
            Warp::xNorm(mini.center().x(), screen.x(), screen.width()),
            m_warp
        ) - Warp::warpForward(
            Warp::xNorm(cursorPos.x(), screen.x(), screen.width()),
            m_warp
        );

    effects->activateWindow(w);
    if (Window *window = w->window()) {
        window->performMousePressCommand(
            Options::MouseUnrestrictedMove,
            cursorPos
        );
    }

    m_dragOverride = DragOverride();
}

void StageManagerEffect::slotWindowDeleted(EffectWindow *w)
{
    removeFromStrip(w);
    if (const auto it = m_windows.find(w); it != m_windows.end()) {
        releaseMiniatureTexture(*it);
    }
    m_windows.remove(w);

    if (m_drag.window == w) {
        m_drag = DragState();
    }

    if (m_pendingGrab.window == w) {
        m_pendingGrab = PendingGrab();
    }
}

void StageManagerEffect::slotWindowStartUserMovedResized(EffectWindow *w)
{
    if (!w->isUserMove() || w->isUserResize()) {
        /**
         * A user-initiated resize of a parked window means the user takes
         * ownership of its size again — stop tracking it as parked. (A
         * miniature is minimized and cannot be user-resized; keep its state.)
         */
        if (w->isUserResize()) {
            const auto it = m_windows.find(w);
            if (it != m_windows.end() && !it->miniature) {
                releaseMiniatureTexture(*it);
                m_windows.erase(it);
            }
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
    m_drag.grabFrac = QPointF(
        (cursor.x() - frame.x()) / frame.width(),
        (cursor.y() - frame.y()) / frame.height()
    );

    const RectF screen = w->screen()->geometryF();
    const double uCursor = Warp::warpForward(
        Warp::xNorm(cursor.x(), screen.x(), screen.width()),
        m_warp
    );
    const double uCenter = Warp::warpForward(
        Warp::xNorm(frame.center().x(), screen.x(), screen.width()),
        m_warp
    );
    m_drag.logicalOffset = uCenter - uCursor;

    if (m_dragOverride.window == w) {
        /**
         * Drag started by grabbing a miniature: anchor to where the miniature
         * was, not to the full-size real frame.
         */
        m_drag.grabFrac = m_dragOverride.grabFrac;
        m_drag.logicalOffset = m_dragOverride.logicalOffset;
    }

    if (m_gridMode == GridDuringDrag
        && m_gridTimeline.direction() != TimeLine::Forward
    ) {
        m_gridTimeline.toggleDirection();
        effects->addRepaintFull();
    }

    if (m_dragRails
        && m_gridMode != GridOff
        && m_railTimeline.direction() != TimeLine::Forward
    ) {
        m_railTimeline.setDuration(RailFadeIn);
        m_railTimeline.toggleDirection();

        effects->addRepaintFull();
    }

    updateDrag();
}

void StageManagerEffect::slotWindowStepUserMovedResized(
    EffectWindow *w,
    const RectF &geometry
) {
    /**
     * The signal's geometry is KWin's own unwarped move-loop rect; the painted
     * position is derived from the cursor instead.
     */
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

void StageManagerEffect::detectShake(double cursorX)
{
    /**
     * Desktop5's gesture: >= ShakeCount horizontal direction reversals, each
     * after >= ShakeMinTravel px, inside a rolling ShakeWindow — filters
     * ordinary dragging while catching a deliberate wiggle.
     */
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

void StageManagerEffect::stash()
{
    if (m_drag.window) {
        return;
    }

    stashAll(nullptr);
}

void StageManagerEffect::stageActiveWindowAlone()
{
    if (m_drag.window) {
        return;
    }

    /**
     * macOS "click the desktop / choose a window" model: the focused window
     * stays, everything else goes to the strip. Without a stageable focused
     * window this is the same as staging everything.
     */
    EffectWindow *active = effects->activeWindow();
    stashAll(isRelevant(active) && !active->isMinimized() ? active : nullptr);
}

void StageManagerEffect::stageActiveWindow()
{
    if (m_drag.window || !m_stageMode) {
        return;
    }

    EffectWindow *active = effects->activeWindow();
    if (!isRelevant(active) || active->isMinimized()) {
        return;
    }

    const auto it = m_windows.constFind(active);
    if (it != m_windows.constEnd() && it->parked) {
        return;
    }

    // Minimizing hands focus to the next window, so the stage stays usable.
    stripParkWindow(active, m_windows[active], active->frameGeometry());
    effects->addRepaintFull();
}

void StageManagerEffect::nextGroup()
{
    /**
     * Round-robin: the oldest pile (bottom of the strip) comes to the stage
     * and the current stage is parked at the top as the newest — repeated
     * presses walk through every stage in order.
     */
    if (m_drag.window || m_strip.isEmpty() || m_strip.last().windows.isEmpty()) {
        return;
    }

    swapToWindowGroup(m_strip.last().windows.first(), /*parkCenterAtBottom=*/ false);
}

void StageManagerEffect::previousGroup()
{
    /**
     * The exact reverse: the newest pile (top) comes to the stage and the
     * current stage is parked at the bottom as the oldest.
     */
    if (m_drag.window || m_strip.isEmpty() || m_strip.first().windows.isEmpty()) {
        return;
    }

    swapToWindowGroup(m_strip.first().windows.first(), /*parkCenterAtBottom=*/ true);
}

void StageManagerEffect::restoreAll()
{
    const QList<EffectWindow *> parked = m_windows.keys();
    for (EffectWindow *w : parked) {
        const auto it = m_windows.find(w);
        if (it == m_windows.end() || !it->miniature) {
            continue;
        }

        /**
         * Leave the strip first so slotMinimizedChanged takes the plain
         * restore branch (unpark + our animation) rather than a stage swap.
         */
        removeFromStrip(w);
        setMinimizedQuietly(w, false);
    }

    effects->addRepaintFull();
}

void StageManagerEffect::stashAll(EffectWindow *exclude)
{
    LogicalOutput *output = exclude ? exclude->screen() : effects->activeScreen();
    if (!output) {
        return;
    }

    const RectF screen = output->geometryF();
    const RectF workArea = effects->clientArea(PlacementArea, output);
    const double screenCenterX = screen.center().x();

    /**
     * Collect every other full-size window, topmost first (recency order —
     * recent windows get the inner, larger columns).
     */
    std::vector<EffectWindow *> candidates;

    const auto order = effects->stackingOrder();
    for (auto it = order.crbegin(); it != order.crend(); ++it) {
        EffectWindow *w = *it;
        if (w == exclude
            || !isRelevant(w)
            || w->isMinimized()
            || !w->isOnCurrentDesktop()
            || w->screen() != output
        ) {
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

    if (m_stageMode) {
        for (EffectWindow *w : candidates) {
            stripParkWindow(w, m_windows[w], w->frameGeometry());
        }
        effects->addRepaintFull();

        return;
    }

    /**
     * Split by which half of the screen the window currently occupies (when
     * both sides have park zones — otherwise everything goes to the enabled
     * side), then fill each side's inner column until it is height-full and
     * overflow to the outer column.
     */
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
            if (leftOn
                && rightOn
                && (w->frameGeometry().center().x() < screenCenterX) != (side < 0)
            ) {
                continue;
            }

            const double h = w->frameGeometry().height() * innerScale;

            if (inner.height + h + StashGapPx <= workArea.height()
                || inner.windows.empty()
            ) {
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
            const double colX = Warp::xPixel(
                col->colXNorm,
                screen.x(),
                screen.width()
            );
            double total = -StashGapPx;

            for (EffectWindow *w : col->windows) {
                total += w->frameGeometry().height() * sc + StashGapPx;
            }

            double y = std::max(
                workArea.top() + StashGapPx,
                workArea.center().y() - total / 2.0
            );

            for (EffectWindow *w : col->windows) {
                WindowState &st = m_windows[w];
                const RectF frame = w->frameGeometry();
                if (!st.parked) {
                    st.naturalGeometry = frame;
                }

                QSizeF size = st.naturalGeometry.size() * sc;
                RectF target(QPointF(colX - size.width() / 2.0, y), size);
                if (m_miniatureParking) {
                    clampTiltedIntoArea(
                        target,
                        tiltSign(target, w) * m_stageTilt,
                        workArea
                    );
                } else {
                    if (target.bottom() > workArea.bottom()) {
                        target.moveBottom(workArea.bottom());
                    }

                    if (target.right() > workArea.right() - 4.0) {
                        target.moveRight(workArea.right() - 4.0);
                    }

                    if (target.left() < workArea.left() + 4.0) {
                        target.moveLeft(workArea.left() + 4.0);
                    }
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

void StageManagerEffect::updateDrag()
{
    EffectWindow *w = m_drag.window;
    if (!w) {
        return;
    }

    const RectF screen = w->screen()->geometryF();
    const QPointF cursor = effects->cursorPos();

    /**
     * Grab offset is kept constant in LOGICAL (warped) space, so the window
     * slides along the curve as it is dragged (Desktop5 semantics).
     */
    const double uCursor = Warp::warpForward(
        Warp::xNorm(cursor.x(), screen.x(), screen.width()),
        m_warp
    );

    m_drag.centerXNorm = Warp::warpInverse(uCursor + m_drag.logicalOffset, m_warp);
    m_drag.scale = Warp::windowScale(m_drag.centerXNorm, m_warp);
}

void StageManagerEffect::prePaintScreen(ScreenPrePaintData &data)
{
    if (m_drag.window || hasMiniatures()) {
        data.mask |= PAINT_SCREEN_WITH_TRANSFORMED_WINDOWS;

        /**
         * A miniature is painted at its slot, away from the window's real
         * geometry, so the scene's damage tracking for that window doesn't
         * cover the slot. Anything that autonomously damages the region under
         * a pile — an animated/video wallpaper, a below-layer monitor, another
         * window — would then repaint only its own rect and leave the pile's
         * overlapping slice showing stale pixels. Add each miniature's painted
         * extents to the repaint region unconditionally (cheap, small rects)
         * so any such damage always co-repaints the pile.
         */
        for (auto it = m_windows.constBegin(); it != m_windows.constEnd(); ++it) {
            if (it->miniature) {
                data.paint += miniatureExtents(it.key(), *it).roundedOut();
            }
        }
    }

    if (m_gridMode == GridDuringDrag && !m_gridTimeline.done()) {
        m_gridTimeline.advance(data.view);
    }

    if (!m_railTimeline.done()) {
        m_railTimeline.advance(data.view);
    }

    AnimationEffect::prePaintScreen(data);
}

void StageManagerEffect::prePaintWindow(
    RenderView *view,
    EffectWindow *w,
    WindowPrePaintData &data
) {
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

void StageManagerEffect::paintWindow(
    const RenderTarget &renderTarget,
    const RenderViewport &viewport,
    EffectWindow *w,
    int mask,
    const Region &deviceRegion,
    WindowPaintData &data
) {
    if (w->isDesktop()
        && m_gridShader
        && m_gridMode != GridOff
        && w->frameGeometry().width() >= w->screen()->geometryF().width() * 0.95
    ) {
        /**
         * Paint the wallpaper first, then the warped grid over it — under all
         * other windows, which paint later in the stacking order. The width
         * check targets the full-screen plasmashell desktop; any smaller,
         * content-sized desktop-type window must not get a grid painted over
         * it.
         */
        AnimationEffect::paintWindow(renderTarget, viewport, w, mask, deviceRegion, data);

        const double opacity = (m_gridMode == GridAlways)
            ? 1.0
            : m_gridTimeline.value();
        if (opacity > 0.0) {
            renderGrid(viewport, opacity);
        }

        return;
    }
    /**
     * KWin's item renderer software-clips a window's quads against the paint
     * region using only the paint TRANSLATION — the paint scale is ignored —
     * whenever the region is infinite (which it is under
     * PAINT_SCREEN_WITH_TRANSFORMED_WINDOWS). A window painted scaled near a
     * screen edge then loses everything past (edge - paintedLeft) / scale of its
     * own pixels. A finite region covering the whole target makes the renderer
     * scissor instead (exact for any transform), so hand one down the chain.
     */
    const Region clipRegion = (deviceRegion == Region::infinite())
        ? Region(viewport.deviceRect())
        : deviceRegion;

    if (w == m_drag.window) {
        const auto it = m_windows.constFind(w);
        const RectF frame = w->frameGeometry();
        const QSizeF naturalSize = (it != m_windows.constEnd()
            && !it->naturalGeometry.isEmpty()
        ) ? it->naturalGeometry.size() : frame.size();

        /**
         * m_drag.scale is relative to the NATURAL size; the live buffer is the
         * current (possibly parked) frame, so convert to a paint factor.
         */
        const double factor = (m_drag.scale * naturalSize.width()) / frame.width();
        const QSizeF paintedSize = frame.size() * factor;

        const RectF screen = w->screen()->geometryF();
        const QPointF cursor = effects->cursorPos();
        const double centerX = Warp::xPixel(m_drag.centerXNorm, screen.x(), screen.width());
        const double centerY = cursor.y() + (0.5 - m_drag.grabFrac.y()) * paintedSize.height();

        const QPointF topLeft(
            centerX - paintedSize.width() / 2.0,
            centerY - paintedSize.height() / 2.0
        );

        data.setXScale(data.xScale() * factor);
        data.setYScale(data.yScale() * factor);
        data += (topLeft - frame.topLeft());

        m_drag.paintedRect = RectF(topLeft, paintedSize);

        /**
         * Drag rails: the horizontal grid-line indices behind the painted rect
         * at the window's x. The grid's y coordinate is yn / localScale, so
         * convert through the (unclamped) local scale at the window center.
         */
        if (m_dragRails) {
            const double ls = 1.0 / Warp::warpForwardDeriv(m_drag.centerXNorm, m_warp);
            const double cY = screen.center().y();
            const double idxTop = (topLeft.y() - cY) / (ls * m_gridCellPx);
            const double idxBottom = (topLeft.y() + paintedSize.height() - cY)
                / (ls * m_gridCellPx);

            m_railBand = QVector2D(float(idxTop), float(idxBottom));
        }
    } else {
        const auto it = m_windows.find(w);
        if (it != m_windows.end() && it->miniature) {
            /**
             * Blend from the drag-release rect into the parked slot (tilting in
             * on the way), then hold. Drawn from an offscreen copy as one
             * perspective quad; the real item is not painted at all.
             */
            if (effects->isOpenGLCompositing()) {
                updateMiniatureTexture(w, *it);
                if (paintMiniature(renderTarget, viewport, w, *it, deviceRegion, data)) {
                    return;
                }
            }

            // Fallback: flat, scaled paint of the real item.
            const RectF cur = currentMiniRect(*it);
            const RectF frame = w->frameGeometry();
            const double factor = cur.width() / frame.width();

            data.setXScale(data.xScale() * factor);
            data.setYScale(data.yScale() * factor);
            data += (cur.topLeft() - frame.topLeft());
        }
    }

    AnimationEffect::paintWindow(renderTarget, viewport, w, mask, clipRegion, data);
}

void StageManagerEffect::postPaintScreen()
{
    for (auto it = m_windows.constBegin(); it != m_windows.constEnd(); ++it) {
        if (it->miniature && !it->miniTimeline.done()) {
            effects->addRepaint(
                miniaturePaintedExtents(it.key(), it->miniFrom)
                    .united(miniaturePaintedExtents(it.key(), it->miniRect))
                    .united(miniatureExtents(it.key(), *it))
            );
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

void StageManagerEffect::renderGrid(const RenderViewport &viewport, double opacity)
{
    const Rect device = viewport.scaledRenderRect();

    GLVertexBuffer *vbo = GLVertexBuffer::streamingBuffer();
    vbo->reset();
    vbo->setAttribLayout(
        std::span(GLVertexBuffer::GLVertex2DLayout),
        sizeof(GLVertex2D)
    );

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
    shader->setUniform(
        GLShader::Mat4Uniform::ModelViewProjectionMatrix,
        viewport.projectionMatrix()
    );
    shader->setUniform(m_gridUniforms.gridColor, QVector4D(
        float(m_gridColor.redF()),
        float(m_gridColor.greenF()),
        float(m_gridColor.blueF()), 1.0f
    ));
    shader->setUniform(m_gridUniforms.deadZone, QVector2D(
        float(m_warp.deadZoneLeft),
        float(m_warp.deadZoneRight)
    ));
    shader->setUniform(m_gridUniforms.power, float(m_warp.power));
    shader->setUniform(m_gridUniforms.strength, float(m_warp.strength));
    shader->setUniform(
        m_gridUniforms.halfCellsX,
        float(viewport.renderRect().width() / 2.0 / m_gridCellPx)
    );
    shader->setUniform(
        m_gridUniforms.halfCellsY,
        float(viewport.renderRect().height() / 2.0 / m_gridCellPx)
    );
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
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA); // premultiplied alpha.
    vbo->render(GL_TRIANGLES);
    glDisable(GL_BLEND);
}

void StageManagerEffect::slotWindowFinishUserMovedResized(EffectWindow *w)
{
    if (w != m_drag.window) {
        return;
    }

    if (m_gridMode == GridDuringDrag
        && m_gridTimeline.direction() != TimeLine::Backward
    ) {
        m_gridTimeline.toggleDirection();
        effects->addRepaintFull();
    }

    if (m_railTimeline.direction() != TimeLine::Backward) {
        m_railTimeline.setDuration(RailFadeOut);
        m_railTimeline.toggleDirection();
        effects->addRepaintFull();
    }

    WindowState &st = m_windows[w];
    const RectF from = m_drag.paintedRect.isEmpty()
        ? w->frameGeometry()
        : m_drag.paintedRect;
    const double xn = m_drag.centerXNorm;
    const QPointF cursor = effects->cursorPos();
    const QPointF grabFrac = m_drag.grabFrac;
    const RectF startFrame = m_drag.startFrame;

    m_drag = DragState();

    /**
     * Esc-cancel: KWin restores the initial geometry, so a finish with the
     * frame back at its start position means the move was cancelled (or was a
     * no-op click) — leave everything as it is. A cancelled miniature grab-out
     * leaves the window unminimized at its natural geometry, which is a plain
     * un-parked window.
     */
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
            /**
             * The window was never really resized — KWin's move loop already
             * put the real geometry where an unwarped move would (including
             * its own edge snapping).
             */
            effects->addRepaintFull();

            return;
        }

        /**
         * Restore a parked window: natural size, grabbed point kept under
         * the cursor.
         */
        const QSizeF size = st.naturalGeometry.size();
        QPointF topLeft(
            cursor.x() - grabFrac.x() * size.width(),
            cursor.y() - grabFrac.y() * size.height()
        );
        target = RectF(topLeft, size);
        st.parked = false;
        st.column = -1;
    } else {
        /**
         * Park: snap to the nearest column on this side. Columns live at
         * fractions of the park zone, so they adapt to its size.
         */
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
            /**
             * Real-resize mode has to respect client minimum sizes; a painted
             * miniature can be arbitrarily small.
             */
            size = w->window()->constrainFrameSize(size);
        }

        const double centerX = Warp::xPixel(colXNorm, screen.x(), screen.width());
        target = RectF(
            QPointF(centerX - size.width() / 2.0, from.center().y() - size.height() / 2.0),
            size
        );

        if (m_stageMode) {
            stripParkWindow(w, st, from);
            effects->addRepaintFull();

            return;
        }

        if (m_miniatureParking) {
            /**
             * Wide windows at the outer columns can poke past the screen edge
             * (visible as a cropped miniature) — keep the tilted footprint
             * fully on-screen.
             */
            RectF mini = target;
            clampTiltedIntoArea(mini, tiltSign(mini, w) * m_stageTilt, workArea);

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

double StageManagerEffect::stripSideSign() const
{
    if (Warp::sideEnabled(1.0, m_warp)) {
        return 1.0;
    }

    if (Warp::sideEnabled(-1.0, m_warp)) {
        return -1.0;
    }

    return 0.0;
}

int StageManagerEffect::stripGroupIndexOf(EffectWindow *w) const
{
    for (int i = 0; i < m_strip.size(); ++i) {
        if (m_strip[i].windows.contains(w)) {
            return i;
        }
    }

    return -1;
}

void StageManagerEffect::removeFromStrip(EffectWindow *w)
{
    bool changed = false;
    for (int i = m_strip.size() - 1; i >= 0; --i) {
        changed |= m_strip[i].windows.removeAll(w) > 0;
        if (m_strip[i].windows.isEmpty()) {
            m_strip.removeAt(i);
        }
    }

    if (changed) {
        relayoutStrip();
    }
}

void StageManagerEffect::stripParkWindow(
    EffectWindow *w,
    WindowState &st,
    const RectF &from
) {
    if (stripSideSign() == 0.0) {
        return;
    }

    // Join (or create, at the top) this application's pile.
    const QString cls = w->windowClass();
    int gi = -1;
    for (int i = 0; i < m_strip.size(); ++i) {
        if (m_strip[i].appClass == cls) {
            gi = i;
            break;
        }
    }

    if (gi < 0) {
        if (m_parkNewGroupsAtBottom) {
            m_strip.append(StageGroup{cls, {}});
            gi = m_strip.size() - 1;
        } else {
            m_strip.prepend(StageGroup{cls, {}});
            gi = 0;
        }
    }

    if (!m_strip[gi].windows.contains(w)) {
        m_strip[gi].windows.prepend(w);
    }

    if (!st.parked) {
        st.naturalGeometry = w->frameGeometry();
    }

    if (!st.miniature) {
        st.parked = true;
        st.miniature = true;
        st.column = -1;
        st.miniFrom = from;
        st.miniRect = from; // relayoutStrip retargets to the pile slot
        st.tiltFrom = 0.0;  // flat at release, tilts in with the slide
        st.tiltTo = 0.0;
        st.textureDirty = true;
        st.miniTimeline = TimeLine(m_duration, TimeLine::Forward);
        st.miniTimeline.setEasingCurve(QEasingCurve::OutCubic);

        if (!m_animate) {
            st.miniTimeline.setElapsed(m_duration);
        }

        st.visibleRef = EffectWindowVisibleRef(w, EffectWindow::PAINT_DISABLED_BY_MINIMIZE);

        /**
         * Elevate so the miniature composites above below-layer windows
         * regardless of its minimized stacking position.
         */
        st.parkSerial = ++m_parkSerial;
        w->elevate(true);
        setMinimizedQuietly(w, true);

        if (w->window()) {
            w->window()->moveResize(st.naturalGeometry);
        }
    }

    relayoutStrip();
}

void StageManagerEffect::relayoutStrip()
{
    for (int i = m_strip.size() - 1; i >= 0; --i) {
        if (m_strip[i].windows.isEmpty()) {
            m_strip.removeAt(i);
        }
    }

    const double side = stripSideSign();
    if (side == 0.0 || m_strip.isEmpty()) {
        effects->addRepaintFull();

        return;
    }

    EffectWindow *ref = m_strip.first().windows.first();
    const RectF screen = ref->screen()->geometryF();
    RectF workArea = effects->clientArea(PlacementArea, ref);
    const double stripXNorm = Warp::columnX(side, 0.5, m_warp);
    const double sc = Warp::windowScale(stripXNorm, m_warp);
    const double stripX = Warp::xPixel(stripXNorm, screen.x(), screen.width());
    const double tilt = side * m_stageTilt;

    constexpr double PileOffset = 14.0; // cascade shift inside a pile (max 3 visible)
    constexpr double SlotGap = 28.0;
    constexpr double Margin = 28.0;

    /**
     * The horizontal band the strip occupies: the miniature box width, widened
     * by the perspective growth of a tilted miniature's near edge.
     */
    const double boxW = m_stageMiniWidth * screen.width();
    const double boxH = m_stageMiniHeight * screen.height();
    const RectF bandProbe = tiltedBounds(RectF(0.0, 0.0, boxW, boxH), tilt);
    const double maxW = std::max(boxW, bandProbe.width());

    const double bandLeft = stripX - maxW / 2.0;
    const double bandRight = stripX + maxW / 2.0;

    /**
     * Panels (docks) don't always reserve strut space — a floating or
     * dodge-windows panel leaves PlacementArea at full screen, so it isn't
     * excluded above. Inset the strip past any top/bottom dock that overlaps
     * its horizontal band so piles never render under a panel.
     */
    const auto order = effects->stackingOrder();
    for (EffectWindow *dock : order) {
        if (!dock->isDock() || dock->screen() != ref->screen()) {
            continue;
        }

        const RectF dg = dock->frameGeometry();
        if (dg.right() <= bandLeft || dg.left() >= bandRight) {
            continue; // not over the strip
        }

        if (dg.center().y() < screen.center().y()) {
            workArea.setTop(std::max(workArea.top(), dg.bottom()));
        } else {
            workArea.setBottom(std::min(workArea.bottom(), dg.top()));
        }
    }

    double y = workArea.top() + Margin;
    for (StageGroup &group : m_strip) {
        /**
         * Pile height and top padding come from the projected (tilted) bounds
         * so the near edge of a miniature never runs into its neighbours.
         */
        double pileH = 0.0;
        double topPad = 0.0;
        for (EffectWindow *w : std::as_const(group.windows)) {
            const auto it = m_windows.constFind(w);
            if (it != m_windows.constEnd()) {
                const double s = stripScaleFor(*it, ref, sc);
                const RectF flat(
                    0.0,
                    0.0,
                    it->naturalGeometry.width() * s,
                    it->naturalGeometry.height() * s
                );
                const RectF b = tiltedBounds(flat, tilt);
                pileH = std::max(pileH, b.height());
                topPad = std::max(topPad, -b.top());
            }
        }

        const double extra = PileOffset * std::min<int>(group.windows.size() - 1, 2);
        for (int i = 0; i < group.windows.size(); ++i) {
            const auto it = m_windows.find(group.windows[i]);
            if (it == m_windows.end()) {
                continue;
            }

            const double off = PileOffset * std::min(i, 2);
            const double s = stripScaleFor(*it, ref, sc);
            const QSizeF size(
                it->naturalGeometry.width() * s,
                it->naturalGeometry.height() * s
            );
            RectF slot(QPointF(stripX - size.width() / 2.0 + off, y + topPad + off), size);

            // Keep the projected footprint on screen.
            clampTiltedIntoArea(slot, tilt, workArea);

            const bool tiltChanged = std::abs(it->tiltTo - tilt) > 0.01;
            if (slot != it->miniRect || tiltChanged) {
                it->miniFrom = it->miniRect.isEmpty() ? slot : currentMiniRect(*it);
                it->tiltFrom = it->miniRect.isEmpty() ? tilt : currentTilt(*it);
                it->miniRect = slot;
                it->tiltTo = tilt;
                it->miniTimeline = TimeLine(m_duration, TimeLine::Forward);
                it->miniTimeline.setEasingCurve(QEasingCurve::OutCubic);

                if (!m_animate) {
                    it->miniTimeline.setElapsed(m_duration);
                }
            }
        }

        y += pileH + extra + SlotGap;
    }

    effects->addRepaintFull();
}

void StageManagerEffect::swapToWindowGroup(
    EffectWindow *activated,
    bool parkCenterAtBottom
) {
    const int gi = stripGroupIndexOf(activated);
    if (gi < 0) {
        return;
    }

    m_swapping = true;
    m_parkNewGroupsAtBottom = parkCenterAtBottom;

    const QList<EffectWindow *> group = m_strip[gi].windows;

    /**
     * Park the current center windows; stripParkWindow groups them by app.
     * Group members are excluded — a member restored externally (alt-tab,
     * taskbar) is already back in the center when the swap runs.
     */
    std::vector<EffectWindow *> center;
    const auto order = effects->stackingOrder();
    for (auto it = order.crbegin(); it != order.crend(); ++it) {
        EffectWindow *w = *it;
        if (w == activated || group.contains(w)) {
            continue;
        }

        if (!isRelevant(w) || w->isMinimized() || !w->isOnCurrentDesktop()) {
            continue;
        }

        const auto st = m_windows.constFind(w);
        if (st != m_windows.constEnd() && st->parked) {
            continue;
        }

        center.push_back(w);
    }

    for (EffectWindow *w : center) {
        stripParkWindow(w, m_windows[w], w->frameGeometry());
    }
    m_parkNewGroupsAtBottom = false;

    // Bring the whole group to the stage.
    for (EffectWindow *w : group) {
        const auto it = m_windows.find(w);
        if (it == m_windows.end()) {
            continue;
        }

        if (w->isMinimized()) {
            setMinimizedQuietly(w, false); // slotMinimizedChanged unparks
        } else {
            if (it->miniature) {
                unparkMiniature(w, *it);
            }

            removeFromStrip(w);
        }
    }

    relayoutStrip();
    effects->activateWindow(activated);

    m_swapping = false;
}

void StageManagerEffect::slotWindowActivated(EffectWindow *w)
{
    if (!m_stageMode || m_swapping || !w) {
        return;
    }

    const auto it = m_windows.constFind(w);
    if (it != m_windows.constEnd() && it->miniature) {
        /**
         * Defer one event-loop tick so the task switcher (and its highlight
         * effect) has fully closed before windows start moving.
         */
        QTimer::singleShot(0, this, [this, w]() {
            if (m_windows.contains(w) && stripGroupIndexOf(w) >= 0) {
                swapToWindowGroup(w);
            }
        });
    }
}

void StageManagerEffect::setMinimizedQuietly(EffectWindow *w, bool minimized)
{
    /**
     * Squash/Magic Lamp animate every minimizedChanged unless a fullscreen
     * effect is active. The signal fires synchronously inside setMinimized, so
     *  claiming the fullscreen slot for just this call suppresses their
     * conflicting animation without touching anything else.
     */
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

void StageManagerEffect::parkMiniature(
    EffectWindow *w,
    WindowState &st,
    const RectF &from,
    const RectF &target
) {
    st.parked = true;
    st.miniature = true;
    st.miniRect = target;
    st.miniFrom = m_animate ? from : target;
    st.tiltFrom = 0.0;
    st.tiltTo = tiltSign(target, w) * m_stageTilt;
    st.textureDirty = true;
    st.miniTimeline = TimeLine(m_duration, TimeLine::Forward);
    st.miniTimeline.setEasingCurve(QEasingCurve::OutCubic);

    if (!m_animate) {
        st.miniTimeline.setElapsed(m_duration);
    }

    /**
     * The visible-ref keeps the window's item painted while minimized — which
     * also keeps the client unsuspended, so the miniature stays live. Elevate
     * it above below-layer windows.
     */
    st.visibleRef = EffectWindowVisibleRef(w, EffectWindow::PAINT_DISABLED_BY_MINIMIZE);
    st.parkSerial = ++m_parkSerial;
    w->elevate(true);
    setMinimizedQuietly(w, true);

    /**
     * KWin's move loop dragged the real (invisible) geometry into the flank;
     * put it back so any unminimize restores to the pre-drag position. Same
     * size, so the client never re-layouts.
     */
    if (w->window()) {
        w->window()->moveResize(st.naturalGeometry);
    }
}

void StageManagerEffect::unparkMiniature(EffectWindow *w, WindowState &st)
{
    /**
     * Start from the last PAINTED rect: a relayout just before (strip member
     * removed) may have retargeted miniRect without a frame in between.
     */
    const RectF from = currentMiniRect(st);
    const RectF to = st.naturalGeometry; // real geometry never left here.
    st.parked = false;
    st.miniature = false;
    st.column = -1;
    st.tiltFrom = 0.0;
    st.tiltTo = 0.0;
    st.visibleRef = EffectWindowVisibleRef();
    releaseMiniatureTexture(st);
    w->elevate(false);

    /**
     * On an external unminimize (taskbar, alt-tab) with Squash or Magic Lamp
     * active, their unminimize animation is already playing — adding ours on
     * top would double-transform the window.
     */
    const bool otherAnimation = !m_quietMinimize
        && (effects->isEffectLoaded(QStringLiteral("squash"))
            || effects->isEffectLoaded(QStringLiteral("magiclamp")));

    if (m_animate && !otherAnimation) {
        animate(
            w,
            Size,
            0,
            m_duration,
            FPx2(to.width(), to.height()),
            QEasingCurve(QEasingCurve::OutCubic),
            0,
            FPx2(from.width(), from.height())
        );
        animate(
            w,
            Translation,
            0,
            m_duration,
            FPx2(0.0, 0.0),
            QEasingCurve(QEasingCurve::OutCubic),
            0,
            FPx2(from.center().x() - to.center().x(), from.center().y() - to.center().y())
        );
    }

    effects->addRepaintFull();
}

void StageManagerEffect::commitGeometry(
    EffectWindow *w,
    const RectF &from,
    const RectF &to
) {
    Window *window = w->window();
    if (!window) {
        return;
    }

    /**
     * CrossFadePrevious snapshots the old content when the animation starts,
     * so it must be scheduled before the real geometry change. Skip it when
     * wobbly windows is loaded — both effects redirect the window in the
     * drawWindow chain and the loser's snapshot silently vanishes.
     */
    const bool crossFade = m_animate && !effects->isEffectLoaded(
        QStringLiteral("wobblywindows")
    );
    if (crossFade) {
        animate(
            w,
            CrossFadePrevious,
            0,
            m_duration,
            FPx2(1.0),
            QEasingCurve(QEasingCurve::OutCubic),
            0,
            FPx2(0.0)
        );
    }

    window->moveResize(to);

    if (m_animate) {
        animate(
            w,
            Size,
            0,
            m_duration,
            FPx2(to.width(), to.height()),
            QEasingCurve(QEasingCurve::OutCubic),
            0,
            FPx2(from.width(), from.height())
        );
        /**
         * Size anchors about the center, so the translation compensates for the
         * center shift between the painted drag rect and the committed rect.
         */
        animate(
            w,
            Translation,
            0,
            m_duration,
            FPx2(0.0, 0.0),
            QEasingCurve(QEasingCurve::OutCubic),
            0,
            FPx2(from.center().x() - to.center().x(), from.center().y() - to.center().y())
        );
    }
}

void StageManagerEffect::slotWindowFrameGeometryChanged(
    EffectWindow *w,
    const RectF &oldGeometry
) {
    const auto it = m_windows.find(w);
    if (it == m_windows.end()) {
        return;
    }

    if (it->miniature) {
        /**
         * A miniature's real frame never moves by us; a client-side resize
         * while parked just changes what the miniature shows. Adopt it as the
         * new natural size (a pile relayout follows) — never drop the state,
         * which would strand the window minimized and elevated.
         */
        it->textureDirty = true;
        // Follow any relocation (output changes) so the restore lands on the real frame.
        it->naturalGeometry = w->frameGeometry();
        if (w->frameGeometry().size() != oldGeometry.size()
            && stripGroupIndexOf(w) >= 0
        ) {
            relayoutStrip();
        }

        return;
    }

    if (it->awaitingCommit) {
        /**
         * Adopt whatever the client actually committed (it may have refused a
         * sub-minimum size) so restore/re-drag bookkeeping never desyncs.
         */
        it->awaitingCommit = false;

        return;
    }

    if (it->parked && w != m_drag.window
        && w->frameGeometry().size() != oldGeometry.size()) {
        /**
         * Someone else (client or user) resized a parked window — it owns its
         * geometry again.
         */
        m_windows.erase(it);
    }
}

} // namespace KWin
