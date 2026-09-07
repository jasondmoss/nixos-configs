/*
    SPDX-License-Identifier: GPL-2.0-or-later
*/

#pragma once

#include <KCModule>

#include "ui_stagemanager_config.h"

namespace KWin
{

class StageManagerEffectConfig : public KCModule
{
    Q_OBJECT

public:
    explicit StageManagerEffectConfig(QObject *parent, const KPluginMetaData &data);

public Q_SLOTS:
    void save() override;

private:
    Ui::StageManagerEffectConfigForm m_ui;
};

} // namespace KWin
