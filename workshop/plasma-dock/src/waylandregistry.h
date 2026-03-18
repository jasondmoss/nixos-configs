#pragma once

// ─────────────────────────────────────────────────────────────────────────────
// WaylandRegistry
//
// This is the piece that bridges Qt's opaque Wayland integration and the
// raw protocol globals we need (specifically zwlr_layer_shell_v1).
//
// WHY THIS EXISTS:
// Qt's Wayland platform plugin registers its own wl_registry listener to
// grab globals like wl_compositor, xdg_wm_base, etc.  It does NOT know
// about wlr-layer-shell — that's a compositor extension, not a standard
// Wayland protocol.  So we have to walk the registry ourselves at startup,
// in parallel with Qt's own listener, and stash any globals we care about.
//
// This is a singleton because there's only one wl_display per process and
// therefore only one registry.  Create it AFTER QGuiApplication but BEFORE
// any QWindow is shown.
//
// Usage:
//   // In main(), after QGuiApplication construction:
//   WaylandRegistry::instance()->init();
//   // Then create and show your LayerShellWindow normally.
// ─────────────────────────────────────────────────────────────────────────────

#include <QObject>

struct wl_display;
struct wl_registry;
struct zwlr_layer_shell_v1;

class WaylandRegistry : public QObject
{
    Q_OBJECT

public:
    static WaylandRegistry *instance();

    // Call once after QGuiApplication is constructed.
    // Blocks until the initial registry round-trip completes so that by the
    // time init() returns, layerShell() is valid (or nullptr if unsupported).
    void init();

    zwlr_layer_shell_v1 *layerShell() const { return m_layerShell; }

    bool isSupported() const { return m_layerShell != nullptr; }

Q_SIGNALS:
    void layerShellAvailable();

private:
    explicit WaylandRegistry(QObject *parent = nullptr);

    // Static C trampolines for wl_registry_listener
    static void registryGlobal(void *data,
                                wl_registry *registry,
                                uint32_t name,
                                const char *interface,
                                uint32_t version);
    static void registryGlobalRemove(void *data,
                                      wl_registry *registry,
                                      uint32_t name);

    wl_display            *m_display    = nullptr;
    wl_registry           *m_registry   = nullptr;
    zwlr_layer_shell_v1   *m_layerShell = nullptr;
};
