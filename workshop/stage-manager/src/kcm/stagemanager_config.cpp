/**
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#include "stagemanager_config.h"

// KConfigSkeleton, generated from stagemanager.kcfg
#include "stagemanagerconfig.h"
#include "../shortcuts.h"

#include <KActionCollection>
#include <KGlobalAccel>
#include <KLocalizedString>
#include <KPluginFactory>
#include <KShortcutsEditor>

#include <QAction>
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

    /**
     * Mirror the effect's global shortcuts (same component and object names)
     * so they can be rebound right here as well as under Shortcuts → KWin.
     */
    m_actionCollection = new KActionCollection(this, QStringLiteral("kwin"));
    m_actionCollection->setComponentDisplayName(i18n("KWin"));
    m_actionCollection->setConfigGroup(QStringLiteral("StageManager"));
    m_actionCollection->setConfigGlobal(true);

    for (const auto &def : StageManagerShortcuts::Actions) {
        QAction *action = m_actionCollection->addAction(
            QString::fromLatin1(def.objectName)
        );
        action->setProperty("isConfigurationAction", true);
        action->setText(i18n(def.text));
        KGlobalAccel::self()->setDefaultShortcut(action, {def.defaultShortcut});
        KGlobalAccel::self()->setShortcut(action, {def.defaultShortcut});
    }

    m_editor = new KShortcutsEditor(
        m_actionCollection,
        widget(),
        KShortcutsEditor::GlobalAction,
        KShortcutsEditor::LetterShortcutsDisallowed
    );
    m_ui.formLayout->addRow(m_editor);
    connect(m_editor, &KShortcutsEditor::keyChange, this, &KCModule::markAsChanged);
}

StageManagerEffectConfig::~StageManagerEffectConfig()
{
    // Discard unsaved edits (KShortcutsEditor applies them live).
    m_editor->undo();
}

void StageManagerEffectConfig::save()
{
    KCModule::save();
    m_editor->save(); // undo() will restore to this state from now on

    QDBusMessage message = QDBusMessage::createMethodCall(
        QStringLiteral("org.kde.KWin"),
        QStringLiteral("/Effects"),
        QStringLiteral("org.kde.kwin.Effects"),
        QStringLiteral("reconfigureEffect")
    );

    message << QStringLiteral("stagemanager");
    QDBusConnection::sessionBus().send(message);
}

void StageManagerEffectConfig::defaults()
{
    m_editor->allDefault();
    KCModule::defaults();
}

} // namespace KWin

#include "stagemanager_config.moc"

#include "moc_stagemanager_config.cpp"
