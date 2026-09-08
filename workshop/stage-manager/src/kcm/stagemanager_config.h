/*
    SPDX-License-Identifier: GPL-2.0-or-later
*/

#pragma once

#include <KCModule>

#include "ui_stagemanager_config.h"

class KActionCollection;
class KShortcutsEditor;

namespace KWin
{

class StageManagerEffectConfig : public KCModule
{
    Q_OBJECT

public:
    explicit StageManagerEffectConfig(QObject *parent, const KPluginMetaData &data);
    ~StageManagerEffectConfig() override;

public Q_SLOTS:
    void save() override;
    void defaults() override;

private:
    Ui::StageManagerEffectConfigForm m_ui;
    KActionCollection *m_actionCollection = nullptr;
    KShortcutsEditor *m_editor = nullptr;
};

} // namespace KWin
