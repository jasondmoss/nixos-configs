import QtQuick

// ─────────────────────────────────────────────────────────────────────────────
// DockIconPlaceholder
//
// Temporary stand-in while we validate the layer shell plumbing.
// This will evolve into DockIcon.qml once AppModel (the KService-backed
// list model) is wired in.
//
// The magnification math is already here — wire `mouseX` from the parent
// Row's MouseArea when you graduate from placeholder to real icons.
// ─────────────────────────────────────────────────────────────────────────────
Item {
    id: root

    property real size:        48
    property real hoverScale:  1.0   // driven externally by parent's MouseArea
    property bool isRunning:   false // true when a matching window is open
    property bool isHovered:   false

    width:  size
    height: size + indicatorArea.height + 4

    // ── Icon image ─────────────────────────────────────────────────────────
    Rectangle {
        id: iconRect

        width:  root.size
        height: root.size
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom:           indicatorArea.top
        anchors.bottomMargin:     4

        radius:         12
        color:          Qt.rgba(0.2, 0.5, 0.9, 0.8)   // placeholder colour
        border.color:   Qt.rgba(1, 1, 1, 0.15)
        border.width:   1

        // ── Scale animation ────────────────────────────────────────────────
        // The parent Row will update hoverScale via a distance function.
        // Animating the scale here (rather than in the parent) keeps each
        // icon's spring isolated — no jank propagation.
        scale: root.hoverScale
        transformOrigin: Item.Bottom   // Grow upward, like macOS

        Behavior on scale {
            SpringAnimation {
                spring:   4.0
                damping:  0.5
                epsilon:  0.01
            }
        }

        // App initial — placeholder for real icon image
        Text {
            anchors.centerIn: parent
            text:             "A"
            font.pixelSize:   root.size * 0.45
            font.bold:        true
            color:            "white"
        }

        // Hover glow  (subtle — don't overdo it)
        Rectangle {
            anchors.fill:   parent
            radius:         parent.radius
            color:          "transparent"
            border.color:   Qt.rgba(1, 1, 1, root.isHovered ? 0.30 : 0.0)
            border.width:   1

            Behavior on border.color {
                ColorAnimation { duration: 120 }
            }
        }
    }

    // ── Running indicator dot ──────────────────────────────────────────────
    // A subtle coloured dot below the icon — same visual language as macOS.
    // Driven by `isRunning` which AppModel will update via KWindowSystem.
    Item {
        id: indicatorArea
        width:  parent.width
        height: 6
        anchors.bottom: parent.bottom

        Rectangle {
            anchors.centerIn: parent
            width:   5
            height:  5
            radius:  2.5
            color:   "#5ac8fa"   // macOS-ish blue — will pick up accent colour later
            opacity: root.isRunning ? 1.0 : 0.0

            Behavior on opacity {
                NumberAnimation { duration: 200 }
            }
        }
    }

    // ── Tooltip ───────────────────────────────────────────────────────────
    // A basic label that appears on hover.  Will be replaced with a proper
    // KToolTip / Kirigami tooltip for a11y compliance.
    Rectangle {
        id: tooltip
        anchors.bottom: iconRect.top
        anchors.bottomMargin: 6
        anchors.horizontalCenter: parent.horizontalCenter

        width:          tooltipLabel.implicitWidth + 16
        height:         tooltipLabel.implicitHeight + 8
        radius:         6
        color:          Qt.rgba(0.05, 0.05, 0.05, 0.85)
        border.color:   Qt.rgba(1, 1, 1, 0.12)
        border.width:   1
        visible:        root.isHovered

        Text {
            id: tooltipLabel
            anchors.centerIn: parent
            text:       "App Name"    // bind to model.name when real
            color:      "white"
            font.pixelSize: 12
        }
    }
}
