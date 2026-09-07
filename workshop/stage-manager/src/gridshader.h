/**
 * SPDX-License-Identifier: GPL-2.0-or-later
 *
 * Fragment shader for the warped grid background, ported from Desktop5's grid
 * shader semantics: vertical lines live in LOGICAL space (warped by the same
 * curve that drives window scaling), horizontal lines are compressed by the
 * curve's local scale so they converge toward the screen equator in the
 * flanks. Each line is a crisp core plus a soft glow halo; lines fade toward
 * the screen edges but never fully disappear.
 *
 * KWin's shader preprocessor injects the #version line and GLES precision
 * qualifiers, and rewrites in/out for legacy contexts — write modern GLSL
 * with no version header.
 */

#pragma once

#include <QByteArray>

namespace KWin
{

inline const QByteArray s_gridFragmentSource = QByteArrayLiteral(R"(
uniform sampler2D sampler; // unused; present for the MapTexture trait contract
in vec2 texcoord0;
out vec4 fragColor;

uniform vec4 gridColor;     // straight alpha
uniform vec2 deadZones;     // x = left side, y = right side; >= 0.999 disables the side
uniform float power;
uniform float strength;
uniform float halfCellsX;   // half screen width in grid cells
uniform float halfCellsY;   // half screen height in grid cells
uniform float corePx;
uniform float glowPx;
uniform float glowStrength;
uniform float intensity;
uniform float fadeStart;
uniform float fadeFloor;
uniform float backdrop;
uniform float gridOpacity;  // master fade (drag-only mode)
uniform float dragActive;   // drag-rails fade 0..1
uniform vec2 dragBand;      // horizontal line-index range behind the dragged window
uniform float railGain;     // brightness multiplier on highlighted rails
uniform float railThickness;// width multiplier on highlighted rails

float dzFor(float x)
{
    return (x < 0.0) ? deadZones.x : deadZones.y;
}

float flankDist(float x)
{
    float dz = dzFor(x);
    if (dz >= 0.999) {
        return 0.0;
    }
    return max(0.0, abs(x) - dz) / (1.0 - dz);
}

float warpForward(float x)
{
    float fd = flankDist(x);
    return x + sign(x) * pow(fd, power) * strength;
}

float localScale(float x)
{
    float dz = dzFor(x);
    if (dz >= 0.999) {
        return 1.0;
    }
    float fd = max(0.0, abs(x) - dz) / (1.0 - dz);
    float deriv = power * pow(fd, max(power - 1.0, 0.0)) * strength / (1.0 - dz);
    return 1.0 / (1.0 + deriv);
}

float lineIntensity(float coord, float coreW, float glowW)
{
    // coord is in cell units; distance to the nearest line converted to
    // screen pixels through the analytic pixel footprint.
    float d = abs(fract(coord + 0.5) - 0.5) / max(fwidth(coord), 1e-6);
    float core = 1.0 - smoothstep(0.0, coreW, d);
    float glow = (1.0 - smoothstep(0.0, glowW, d)) * glowStrength;
    return core + glow;
}

void main()
{
    float xn = texcoord0.x * 2.0 - 1.0;
    float yn = texcoord0.y * 2.0 - 1.0;

    float u = warpForward(xn);
    float ls = localScale(xn);

    float vLines = lineIntensity(u * halfCellsX, corePx, glowPx);

    // Drag rails: horizontal lines whose index passes behind the dragged
    // window brighten and thicken across the full screen width.
    float coordH = yn / ls * halfCellsY;
    float band = clamp(min(coordH - dragBand.x, dragBand.y - coordH) + 0.5, 0.0, 1.0) * dragActive;
    float hLines = lineIntensity(coordH,
                                 corePx * mix(1.0, railThickness, band),
                                 glowPx * mix(1.0, railThickness, band))
        * mix(1.0, railGain, band);

    // Edge fade belongs to the compression; an unwarped side stays uniform.
    float fade = (dzFor(xn) >= 0.999)
        ? 1.0
        : mix(1.0, fadeFloor, smoothstep(fadeStart, 1.0, abs(xn)));
    float line = clamp(max(vLines, hLines) * intensity * fade, 0.0, 1.0);

    // Dark backdrop under the lines; premultiplied-alpha output.
    float aLine = line * gridColor.a;
    vec3 rgb = gridColor.rgb * aLine;
    float a = aLine + backdrop * (1.0 - aLine);
    fragColor = vec4(rgb, a) * gridOpacity;
}
)");

} // namespace KWin
