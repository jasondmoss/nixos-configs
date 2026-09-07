/**
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#include "stagemanager.h"

namespace KWin
{

    KWIN_EFFECT_FACTORY_SUPPORTED(
        StageManagerEffect,
        "metadata.json",
        return StageManagerEffect::supported();
    )

} // namespace KWin

#include "main.moc"
