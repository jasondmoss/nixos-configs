'use strict';

// Injected into app.asar by default.nix (patch-asar.py) as the package.json
// "main": left-click on the tray icon runs the tray menu's "Show App" item.
//
// The app gives its Tray a context menu but no 'click' listener. On Linux the
// StatusNotifierItem host (KDE) sends Activate on left-click, which Electron
// emits as 'click' — so left-click did nothing and only right-click worked.
// Hooking Tray.prototype.setContextMenu needs no minified names, so this
// survives app updates as long as the menu keeps a "Show App" (or first) item.

const { Tray } = require('electron');

const menus = new WeakMap();
const setContextMenu = Tray.prototype.setContextMenu;

Tray.prototype.setContextMenu = function (menu) {
    if (!menus.has(this)) {
        this.on('click', () => {
            const items = menus.get(this)?.items ?? [];
            const item = items.find((i) => /^show app$/i.test(i.label)) ?? items[0];
            if (item && item.enabled !== false) item.click();
        });
    }
    menus.set(this, menu);
    return setContextMenu.call(this, menu);
};

require(@ORIGINAL_MAIN@);
