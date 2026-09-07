/**
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#include "stagemanager_config.h"

// KConfigSkeleton, generated from stagemanager.kcfg
#include "stagemanagerconfig.h"

#include <KPluginFactory>

#include <QDBusConnection>
#include <QDBusMessage>

K_PLUGIN_CLASS(KWin::StageManagerEffectConfig)

namespace KWin
{

StageManagerEffectConfig::StageManagerEffectConfig(
    QObject *parent,
    const KPluginMetaData &data
) : KCModule(parent, data)
{
    m_ui.setupUi(widget());

    StageManagerConfig::instance(QStringLiteral("kwinrc"));
    addConfig(StageManagerConfig::self(), widget());
}

void StageManagerEffectConfig::save()
{
    KCModule::save();
    QDBusMessage message = QDBusMessage::createMethodCall(
        QStringLiteral("org.kde.KWin"),
        QStringLiteral("/Effects"),
        QStringLiteral("org.kde.kwin.Effects"),
        QStringLiteral("reconfigureEffect")
    );

    message << QStringLiteral("stagemanager");
    QDBusConnection::sessionBus().send(message);
}

} // namespace KWin

#include "stagemanager_config.moc"

#include "moc_stagemanager_config.cpp"
