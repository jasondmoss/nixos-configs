/*
    SPDX-License-Identifier: GPL-2.0-or-later
*/

#pragma once

#include <KCModule>

#include "ui_spacialdesktop_config.h"

namespace KWin
{

class SpacialDesktopEffectConfig : public KCModule
{
    Q_OBJECT

public:
    explicit SpacialDesktopEffectConfig(QObject *parent, const KPluginMetaData &data);

public Q_SLOTS:
    void save() override;

private:
    Ui::SpacialDesktopEffectConfigForm m_ui;
};

} // namespace KWin
