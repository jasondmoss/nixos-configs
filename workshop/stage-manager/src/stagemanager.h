/**
 * SPDX-License-Identifier: GPL-2.0-or-later
 *
 * Stage Manager — Scott Jenson's Desktop5 spatial desktop concept for KWin.
 *
 * Windows shrink along a warp curve as they are dragged toward the screen
 * flanks and park there as small, live, fully interactive windows. During the
 * drag the shrink is a cosmetic paint transform (input is captive to the move
 * operation); on release the final geometry is committed for real, so parked
 * windows need no input remapping.
 */

#pragma once

#include "warpmath.h"

#include "core/rect.h"
#include "effect/animationeffect.h"
#include "effect/effectwindow.h"
#include "effect/timeline.h"

#include <QColor>
#include <QHash>
#include <QMatrix4x4>
#include <QPointF>
#include <QVector2D>

#include <array>
#include <chrono>
#include <memory>
#include <vector>

namespace KWin
{

class GLFramebuffer;
class GLShader;
class GLTexture;
class LogicalOutput;
class RenderTarget;
class RenderViewport;

class StageManagerEffect : public AnimationEffect
{
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "org.kde.KWin.Effect.StageManager1")

public:
    StageManagerEffect();
    ~StageManagerEffect() override;

    static bool supported();

public Q_SLOTS:
    /**
     * D-Bus (org.kde.KWin.Effect.StageManager1 at
     * /org/kde/KWin/Effect/StageManager1): park every managed window on the
     * active screen into the strip / restore all parked miniatures. Bindable to
     * a shortcut via any D-Bus caller.
     */
    Q_SCRIPTABLE void stash();
    Q_SCRIPTABLE void restoreAll();
    Q_SCRIPTABLE void stageActiveWindowAlone(); // park every other window
    Q_SCRIPTABLE void stageActiveWindow();      // park the focused window
    Q_SCRIPTABLE void nextGroup();              // round-robin through the piles
    Q_SCRIPTABLE void previousGroup();

    void reconfigure(ReconfigureFlags flags) override;
    void prePaintScreen(ScreenPrePaintData &data) override;
    void prePaintWindow(
        RenderView *view,
        EffectWindow *w,
        WindowPrePaintData &data
    ) override;
    void paintWindow(
        const RenderTarget &renderTarget,
        const RenderViewport &viewport,
        EffectWindow *w,
        int mask,
        const Region &deviceRegion,
        WindowPaintData &data
    ) override;
    void postPaintScreen() override;
    bool isActive() const override;
    int requestedEffectChainPosition() const override;

private Q_SLOTS:
    void slotWindowAdded(EffectWindow *w);
    void slotWindowDeleted(EffectWindow *w);
    void slotWindowActivated(EffectWindow *w);
    void slotWindowStartUserMovedResized(EffectWindow *w);
    void slotWindowStepUserMovedResized(EffectWindow *w, const RectF &geometry);
    void slotWindowFinishUserMovedResized(EffectWindow *w);
    void slotWindowFrameGeometryChanged(EffectWindow *w, const RectF &oldGeometry);
    void slotWindowDamaged(EffectWindow *w);
    void slotMinimizedChanged(EffectWindow *w);
    void slotMouseChanged(
        const QPointF &pos,
        const QPointF &oldpos,
        Qt::MouseButtons buttons,
        Qt::MouseButtons oldbuttons,
        Qt::KeyboardModifiers modifiers,
        Qt::KeyboardModifiers oldmodifiers
    );

private:
    struct WindowState {
        RectF naturalGeometry;  // full-size geometry to restore to.
        bool parked = false;
        int column = -1;        // 0 = inner, 1 = outer (side implied by position).
        bool awaitingCommit = false;

        /**
         * LicenseLive-miniature mode: the window is really minimized; a
         * visible-ref keeps its item painted (which also keeps the client
         * unsuspended, so the miniature stays live), and we paint it scaled at
         * miniRect.
         */
        bool miniature = false;
        RectF miniRect;         // where the miniature's frame is painted (untilted).
        RectF miniFrom;         // transition start rect (park-in animation).
        TimeLine miniTimeline;  // park-in transition progress.
        double tiltFrom = 0.0;  // signed tilt (degrees) at transition start.
        double tiltTo = 0.0;    // signed tilt (degrees) at rest.
        quint64 parkSerial = 0; // elevation order: higher = painted on top

        EffectWindowVisibleRef visibleRef;

        /**
         * Offscreen copy of the window (expandedGeometry, device pixels,
         * mipmapped). The miniature is drawn from it as a single perspective
         * quad — KWin's item renderer software-clips scaled quads by their
         * untransformed extents, which cut miniatures near a screen edge.
         */
        std::shared_ptr<GLTexture> texture;
        std::shared_ptr<GLFramebuffer> fbo;
        RectF textureRect;      // logical rect the texture covers.
        bool textureDirty = true;
    };

    struct DragState {
        EffectWindow *window = nullptr;
        RectF startFrame;        // real geometry at drag start (Esc-cancel detection).
        QPointF grabFrac;        // grab point as a fraction of the frame (scale-invariant).
        double logicalOffset = 0.0; // warped-space offset between window center and cursor.
        double centerXNorm = 0.0;   // current physical normalized x of the window center.
        double scale = 1.0;         // current warp scale (relative to natural size).
        RectF paintedRect;          // last rect the window was painted at.

        // Shake-to-stash detection (Desktop5 dials).
        int shakeDir = 0;
        double shakeLastX = 0.0;

        std::vector<std::chrono::steady_clock::time_point> shakeTimes;

        bool shook = false;
    };

    struct PendingGrab {
        EffectWindow *window = nullptr;
        QPointF pressPos;
        QPointF grabFrac; // press position as a fraction of the miniature rect.
    };

    struct DragOverride {
        EffectWindow *window = nullptr;
        QPointF grabFrac;

        double logicalOffset = 0.0;
    };

    enum GridMode {
        GridOff = 0,
        GridAlways = 1,
        GridDuringDrag = 2,
    };

    bool isRelevant(EffectWindow *w) const;
    void beginMiniatureDrag(EffectWindow *w, const QPointF &cursorPos);
    void updateDrag();
    void commitGeometry(EffectWindow *w, const RectF &from, const RectF &to);
    void parkMiniature(
        EffectWindow *w,
        WindowState &st,
        const RectF &from,
        const RectF &target
    );
    void unparkMiniature(EffectWindow *w, WindowState &st);
    // Stage manager: parked windows grouped by application into strip piles.
    struct StageGroup {
        QString appClass;
        QList<EffectWindow *> windows; // front = most recent (pile top).
    };

    double stripSideSign() const;
    int stripGroupIndexOf(EffectWindow *w) const;
    void stripParkWindow(EffectWindow *w, WindowState &st, const RectF &from);
    void removeFromStrip(EffectWindow *w);
    void relayoutStrip();
    void swapToWindowGroup(EffectWindow *activated, bool parkCenterAtBottom = false);
    void setupShortcuts();

    bool hasMiniatures() const;
    static RectF currentMiniRect(const WindowState &st);
    static double currentTilt(const WindowState &st);
    static RectF miniaturePaintedExtents(EffectWindow *w, const RectF &paintedFrameRect);
    void setMinimizedQuietly(EffectWindow *w, bool minimized);
    void renderGrid(const RenderViewport &viewport, double opacity);
    void detectShake(double cursorX);
    void stashAll(EffectWindow *exclude);

    // Perspective miniature rendering
    double tiltSign(const RectF &rect, EffectWindow *w) const;
    double stripScaleFor(
        const WindowState &st,
        EffectWindow *ref,
        double warpScale
    ) const;
    static QMatrix4x4 miniatureMatrix(
        const RectF &frameRect,
        const QPointF &originOffset,
        double frameScale,
        double tiltDeg,
        double devScale
    );
    static std::array<QPointF, 4> projectQuad(
        const QMatrix4x4 &m,
        const RectF &localRect,
        double devScale
    );
    static RectF quadBounds(const std::array<QPointF, 4> &quad);
    static bool quadContains(const std::array<QPointF, 4> &quad, const QPointF &p);
    std::array<QPointF, 4> miniatureFrameQuad(
        EffectWindow *w,
        const WindowState &st
    ) const;
    RectF miniatureExtents(EffectWindow *w, const WindowState &st) const;
    RectF tiltedBounds(const RectF &frameRect, double tiltDeg) const;
    void clampTiltedIntoArea(RectF &rect, double tiltDeg, const RectF &area) const;
    void updateMiniatureTexture(EffectWindow *w, WindowState &st);
    void releaseMiniatureTexture(WindowState &st);
    bool paintMiniature(
        const RenderTarget &renderTarget,
        const RenderViewport &viewport,
        EffectWindow *w,
        WindowState &st,
        const Region &deviceRegion,
        const WindowPaintData &data
    );

    Warp::Params m_warp;

    double m_columnInner = 0.62;
    double m_columnOuter = 0.85;
    bool m_animate = true;
    bool m_miniatureParking = true;

    std::chrono::milliseconds m_duration{250};

    // Warped grid background.
    int m_gridMode = GridAlways;

    QColor m_gridColor;

    int m_gridCellPx = 86;
    double m_gridIntensity = 0.5;
    double m_gridBackdrop = 0.0;

    std::unique_ptr<GLShader> m_gridShader;
    TimeLine m_gridTimeline; // drag-only mode fade

    bool m_gridVisibleTarget = false;

    // Shake-to-stash + drag rails.
    bool m_shakeToStash = true;
    bool m_dragRails = true;
    TimeLine m_railTimeline;   // rails fade: 150 ms in, 250 ms out.
    QVector2D m_railBand;      // horizontal line-index band behind the dragged window.
    struct GridUniforms {
        int dragActive = -1;
        int dragBand = -1;
        int railGain = -1;
        int railThickness = -1;
        int gridColor = -1;
        int deadZone = -1;
        int power = -1;
        int strength = -1;
        int halfCellsX = -1;
        int halfCellsY = -1;
        int corePx = -1;
        int glowPx = -1;
        int glowStrength = -1;
        int intensity = -1;
        int fadeStart = -1;
        int fadeFloor = -1;
        int backdrop = -1;
        int gridOpacity = -1;
    } m_gridUniforms;

    QHash<EffectWindow *, WindowState> m_windows;
    DragState m_drag;
    PendingGrab m_pendingGrab;
    DragOverride m_dragOverride;
    bool m_quietMinimize = false; // suppressing other effects' minimize animation right now.
    bool m_unparkByDrag = false;  // miniature is being grabbed back out — skip the restore animation.

    quint64 m_parkSerial = 0;     // bumped on every elevate(true)

    bool m_stageMode = true;
    bool m_swapping = false;      // a stage swap is reshuffling windows — ignore activations
    bool m_parkNewGroupsAtBottom = false; // reverse cycling parks the old stage at the strip's end.
    QList<StageGroup> m_strip;    // top-to-bottom, most recent first.

    // Strip miniature look.
    double m_stageTilt = 25.0;          // degrees about the vertical axis.
    double m_stageMiniWidth = 0.06;     // max miniature width, fraction of screen width.
    double m_stageMiniHeight = 0.14;    // max miniature height, fraction of screen height.
};

} // namespace KWin
