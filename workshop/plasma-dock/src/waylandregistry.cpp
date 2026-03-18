#include "waylandregistry.h"
#include "wlr-layer-shell-unstable-v1-client-protocol.h"

#include <QGuiApplication>
#include <qpa/qplatformnativeinterface.h>
#include <wayland-client.h>

// Version of zwlr_layer_shell_v1 we want to bind to.
// Version 4 adds set_exclusive_edge (Hyprland, KWin >= 6.1 support this).
// We request 4 but degrade gracefully if the compositor only offers 1.
static constexpr uint32_t LAYER_SHELL_VERSION = 4;

// ─────────────────────────────────────────────────────────────────────────────
// Singleton
// ─────────────────────────────────────────────────────────────────────────────
WaylandRegistry *WaylandRegistry::instance()
{
    static WaylandRegistry s_instance;
    return &s_instance;
}

WaylandRegistry::WaylandRegistry(QObject *parent) : QObject(parent) {}

// ─────────────────────────────────────────────────────────────────────────────
// init
// ─────────────────────────────────────────────────────────────────────────────
void WaylandRegistry::init()
{
    // Grab the wl_display Qt is already using.  We share the same display
    // connection — we're not opening a second one.
    QPlatformNativeInterface *native = QGuiApplication::platformNativeInterface();
    m_display = static_cast<wl_display *>(
        native->nativeResourceForIntegration(QByteArrayLiteral("wl_display")));

    if (!m_display) {
        qWarning() << "[WaylandRegistry] Not running under a Wayland compositor.";
        return;
    }

    // Get the registry and attach our listener.
    m_registry = wl_display_get_registry(m_display);

    static const wl_registry_listener s_listener = {
        WaylandRegistry::registryGlobal,
        WaylandRegistry::registryGlobalRemove,
    };
    wl_registry_add_listener(m_registry, &s_listener, this);

    // A round-trip ensures the compositor has processed our registry bind
    // requests and our listener has been called for every advertised global.
    // Two round-trips are needed: first to get global announcements, second
    // to process the bind responses.
    wl_display_roundtrip(m_display);
    wl_display_roundtrip(m_display);

    if (!m_layerShell) {
        qWarning() << "[WaylandRegistry] zwlr_layer_shell_v1 not advertised by compositor."
                      " KWin supports it from Plasma 6.1+.  Check your KWin version.";
    } else {
        qInfo() << "[WaylandRegistry] zwlr_layer_shell_v1 ready.";
        Q_EMIT layerShellAvailable();
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// registryGlobal  (static)
//
// Called once per Wayland global advertised by the compositor.
// We filter for the interfaces we care about and bind them.
// ─────────────────────────────────────────────────────────────────────────────
void WaylandRegistry::registryGlobal(void *data,
                                      wl_registry *registry,
                                      uint32_t name,
                                      const char *interface,
                                      uint32_t version)
{
    auto *self = static_cast<WaylandRegistry *>(data);

    if (qstrcmp(interface, zwlr_layer_shell_v1_interface.name) == 0) {
        // Bind at the minimum of what the compositor offers and what we want.
        uint32_t bindVersion = qMin(version, LAYER_SHELL_VERSION);
        self->m_layerShell = static_cast<zwlr_layer_shell_v1 *>(
            wl_registry_bind(registry, name, &zwlr_layer_shell_v1_interface, bindVersion));
    }
    // Add more globals here as the project grows (e.g. zwp_virtual_keyboard,
    // ext_foreign_toplevel_list for window tracking, etc.)
}

void WaylandRegistry::registryGlobalRemove(void *data,
                                            wl_registry *registry,
                                            uint32_t name)
{
    Q_UNUSED(data)
    Q_UNUSED(registry)
    Q_UNUSED(name)
    // Handle output hotplug / global removal if needed in the future.
}
