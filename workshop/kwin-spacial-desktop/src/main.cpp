/*
    SPDX-License-Identifier: GPL-2.0-or-later
*/

#include "spacialdesktop.h"

namespace KWin
{

KWIN_EFFECT_FACTORY_SUPPORTED(SpacialDesktopEffect,
                              "metadata.json",
                              return SpacialDesktopEffect::supported();)

} // namespace KWin

#include "main.moc"
