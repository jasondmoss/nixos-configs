/*
    SPDX-License-Identifier: GPL-2.0-or-later

    Warp-curve math for the spacial desktop effect, ported from Scott Jenson's
    Desktop5 prototype (js/warp.js). All functions are pure and operate on a
    normalized horizontal coordinate x in [-1, 1] with 0 at the screen center.

    The warp is per-side: each side has its own dead zone, and a dead zone of
    1.0 disables that side entirely (identity curve — no compression, no park
    zone). The window scale is the reciprocal of the curve's derivative, so
    windows shrink at exactly the rate the grid compresses.
*/

#pragma once

#include <algorithm>
#include <cmath>

namespace KWin::Warp
{

// A side with deadZone >= DisabledThreshold is identity (no warp).
inline constexpr double DisabledThreshold = 0.999;

struct Params {
    double deadZoneLeft = 0.72;  // |x| below this stays orthogonal; 1.0 = side off
    double deadZoneRight = 1.0;
    double power = 3.0;          // cubic: C2-smooth bend at the dead-zone boundary
    double strength = 1.33;      // edge compression
    double minScale = 0.20;      // floor for the window scale during drag
};

inline double deadZoneAt(double x, const Params &p)
{
    return (x < 0.0) ? p.deadZoneLeft : p.deadZoneRight;
}

inline bool sideEnabled(double x, const Params &p)
{
    return deadZoneAt(x, p) < DisabledThreshold;
}

// Distance into the flank, normalized 0..1 over the warped region.
inline double flankDist(double x, const Params &p)
{
    const double dz = deadZoneAt(x, p);
    if (dz >= DisabledThreshold) {
        return 0.0;
    }
    return std::max(0.0, std::abs(x) - dz) / (1.0 - dz);
}

// d(warpForward)/dx — always >= 1, grows toward a warped edge.
inline double warpForwardDeriv(double x, const Params &p)
{
    const double dz = deadZoneAt(x, p);
    if (dz >= DisabledThreshold) {
        return 1.0;
    }
    const double fd = std::max(0.0, std::abs(x) - dz) / (1.0 - dz);
    return 1.0 + p.power * std::pow(fd, p.power - 1.0) * p.strength / (1.0 - dz);
}

// Window scale at physical position x: 1.0 in the dead zone, min at a warped edge.
inline double windowScale(double x, const Params &p)
{
    return std::max(p.minScale, 1.0 / warpForwardDeriv(x, p));
}

// Forward warp: PHYSICAL normalized x -> LOGICAL normalized x (closed form).
inline double warpForward(double x, const Params &p)
{
    const double fd = flankDist(x, p);
    return x + std::copysign(std::pow(fd, p.power) * p.strength, x);
}

// Newton inverse of warpForward: LOGICAL -> PHYSICAL. The curve is smooth and
// monotonic per side; 4 iterations give sub-pixel accuracy.
inline double warpInverse(double u, const Params &p)
{
    double x = std::clamp(u, -1.0, 1.0);
    for (int i = 0; i < 4; ++i) {
        x -= (warpForward(x, p) - u) / warpForwardDeriv(x, p);
    }
    return x;
}

// Column position: `frac` (0..1) into a side's park zone. side is -1 or +1.
inline double columnX(double side, double frac, const Params &p)
{
    const double dz = deadZoneAt(side, p);
    return side * (dz + frac * (1.0 - dz));
}

// Pixel-space helpers against a screen rect [left, left+width).
inline double xNorm(double px, double screenLeft, double screenWidth)
{
    const double half = screenWidth / 2.0;
    return (px - screenLeft - half) / half;
}

inline double xPixel(double xn, double screenLeft, double screenWidth)
{
    const double half = screenWidth / 2.0;
    return screenLeft + half + xn * half;
}

} // namespace KWin::Warp
