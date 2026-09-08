/**
 * SPDX-License-Identifier: GPL-2.0-or-later
 *
 * Global shortcut actions shared by the effect (which registers and handles
 * them) and its KCM (which shows them in a KShortcutsEditor). The object names
 * are the KGlobalAccel keys and must never change once shipped.
 */

#pragma once

#include <QKeySequence>
#include <QString>

#include <array>

namespace KWin::StageManagerShortcuts
{

struct Action {
    const char *objectName;
    const char *text; // i18n'd at the point of use.
    QKeySequence defaultShortcut;
};

// clang-format off
inline const std::array<Action, 6> Actions = {{
    {
        "StageManagerStageAlone",
        "Stage Manager: Stage active window alone",
        QKeySequence(Qt::META | Qt::SHIFT | Qt::Key_S)
    },
    {
        "StageManagerStageAll",
        "Stage Manager: Stage all windows",
        QKeySequence(Qt::META | Qt::CTRL | Qt::Key_S)
    },
    {
        "StageManagerRestoreAll",
        "Stage Manager: Bring all windows back",
        QKeySequence(Qt::META | Qt::SHIFT | Qt::Key_R)
    },
    {
        "StageManagerStageWindow",
        "Stage Manager: Stage the active window",
        QKeySequence(Qt::META | Qt::SHIFT | Qt::Key_M)
    },
    {
        "StageManagerNextGroup",
        "Stage Manager: Next stage group",
        QKeySequence(Qt::META | Qt::Key_BracketRight)
    },
    {
        "StageManagerPreviousGroup",
        "Stage Manager: Previous stage group",
        QKeySequence(Qt::META | Qt::Key_BracketLeft)
    }
}};
// clang-format on

enum Index {
    StageAlone = 0,
    StageAll,
    RestoreAll,
    StageWindow,
    NextGroup,
    PreviousGroup,
};

} // namespace KWin::StageManagerShortcuts
