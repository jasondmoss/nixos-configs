/*
    SPDX-License-Identifier: GPL-2.0-or-later
*/

#include "spacialdesktop_config.h"

// KConfigSkeleton, generated from spacialdesktop.kcfg
#include "spacialdesktopconfig.h"

#include <KPluginFactory>

#include <QDBusConnection>
#include <QDBusMessage>

K_PLUGIN_CLASS(KWin::SpacialDesktopEffectConfig)

namespace KWin
{

SpacialDesktopEffectConfig::SpacialDesktopEffectConfig(QObject *parent, const KPluginMetaData &data)
    : KCModule(parent, data)
{
    m_ui.setupUi(widget());

    SpacialDesktopConfig::instance(QStringLiteral("kwinrc"));
    addConfig(SpacialDesktopConfig::self(), widget());
}

void SpacialDesktopEffectConfig::save()
{
    KCModule::save();
    QDBusMessage message = QDBusMessage::createMethodCall(QStringLiteral("org.kde.KWin"),
                                                          QStringLiteral("/Effects"),
                                                          QStringLiteral("org.kde.kwin.Effects"),
                                                          QStringLiteral("reconfigureEffect"));
    message << QStringLiteral("spacialdesktop");
    QDBusConnection::sessionBus().send(message);
}

} // namespace KWin

#include "spacialdesktop_config.moc"

#include "moc_spacialdesktop_config.cpp"
