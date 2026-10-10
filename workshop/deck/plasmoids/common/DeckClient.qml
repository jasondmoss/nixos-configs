/*
    Polls one deck-agent endpoint and exposes the JSON; posts actions.
    SPDX-License-Identifier: GPL-2.0-or-later
*/
import QtQuick

Item {
    id: client

    property int port: 47657
    property string endpoint: "/health"
    property string query: ""
    property int interval: 5000
    property bool active: true

    property var payload: null
    property bool online: false
    property bool everOnline: false
    property string error: ""
    property int failures: 0
    property double lastUpdate: 0

    signal received(var data)

    visible: false

    function url(path)
    {
        return "http://127.0.0.1:" + port + path;
    }

    function refresh()
    {
        const xhr = new XMLHttpRequest();
        const path = endpoint + (query ? (endpoint.indexOf("?") >= 0 ? "&" : "?") + query : "");
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE) {
                return;
            }
            if (xhr.status === 200) {
                try {
                    const parsed = JSON.parse(xhr.responseText);
                    client.payload = parsed;
                    client.online = true;
                    client.everOnline = true;
                    client.error = "";
                    client.failures = 0;
                    client.lastUpdate = Date.now();
                    client.received(parsed);
                } catch (e) {
                    client.error = "Unreadable reply from the Deck agent";
                }
            } else {
                client.failures++;
                if (client.failures >= 2) {
                    client.online = false;
                    client.error = xhr.status === 0
                        ? "Deck agent is not running (systemctl --user start deck-agent)"
                        : "Deck agent error " + xhr.status;
                }
            }
        };
        xhr.open("GET", url(path));
        xhr.timeout = Math.max(3000, interval);
        xhr.send();
    }

    function post(path, body, callback)
    {
        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE) {
                return;
            }
            let reply = null;
            try {
                reply = JSON.parse(xhr.responseText);
            } catch (e) {
                reply = { ok: false, error: "HTTP " + xhr.status };
            }
            if (callback) {
                callback(reply, xhr.status);
            }
        };
        xhr.open("POST", url(path));
        xhr.setRequestHeader("X-Deck", "1");
        xhr.setRequestHeader("Content-Type", "application/json");
        xhr.timeout = 30000;
        xhr.send(JSON.stringify(body || {}));
    }

    Timer {
        interval: client.interval
        running: client.active
        repeat: true
        triggeredOnStart: true
        onTriggered: client.refresh()
    }
}
