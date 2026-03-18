import QtQuick

Item {
    id: root

    // ── Public API ───────────────────────────────────────────────────────────
    required property string iconName
    required property string appName
    required property int    appIndex
    property bool isRunning:  false
    property bool isPinned:   true
    property bool isVertical: false   // true when dock is on left or right edge

    // Magnification — parent passes cursor position in delegate-local space.
    // dockMouseX carries whichever axis is relevant (X for horizontal dock,
    // Y for vertical dock).  DockIcon doesn't need to know which axis it is;
    // the distance maths work identically.
    property real dockMouseX: -999
    property real iconCentreX: -999
    property real baseSize:   48
    property real maxScale:   1.75
    property real magRadius:  120

    opacity: (!root.isPinned || root.isRunning) ? 1.0 : 0.55
    Behavior on opacity { NumberAnimation { duration: 200 } }

    readonly property real dist:        Math.abs(iconCentreX - root.dockMouseX)
    readonly property real t:           Math.max(0, 1 - dist / root.magRadius)
    readonly property real targetScale: dockMouseX < 0 ? 1.0
                                        : 1.0 + (root.maxScale - 1.0) * t * t

    width:  root.baseSize
    height: root.baseSize

    scale: targetScale
    // Horizontal dock: grow upward from bottom.
    // Vertical left dock: grow rightward from left edge.
    transformOrigin: root.isVertical ? Item.Left : Item.Bottom
    Behavior on scale { SpringAnimation { spring: 6; damping: 0.8; epsilon: 0.01 } }

    // ── Icon image ───────────────────────────────────────────────────────────
    Image {
        id: iconImg
        anchors.fill:    parent
        anchors.margins: 4
        source:          root.iconName !== "" ? "image://icon/" + root.iconName : ""
        fillMode:        Image.PreserveAspectFit
        smooth:          true
        antialiasing:    true
        onStatusChanged: {
            if (status === Image.Error)
                source = "image://icon/application-x-executable"
        }
    }

    // ── Running indicator ────────────────────────────────────────────────────
    // Horizontal: dot below the icon centre.
    // Vertical left: dot on the right edge of the icon.
    Rectangle {
        visible: root.isRunning
        width:   6
        height:  6
        radius:  3
        color:   "#ffffff"
        opacity: 0.90

        // Horizontal dock: dot below icon centre (screen-edge side)
        // Vertical left dock: dot on left edge (screen-edge side)
        anchors.horizontalCenter: root.isVertical ? undefined     : parent.horizontalCenter
        anchors.verticalCenter:   root.isVertical ? parent.verticalCenter : undefined
        anchors.bottom:           root.isVertical ? undefined     : parent.bottom
        anchors.left:             root.isVertical ? parent.left   : undefined
        anchors.bottomMargin:     root.isVertical ? 0  : -4
        anchors.leftMargin:       root.isVertical ? -4 : 0
    }

    // ── Tooltip signals ──────────────────────────────────────────────────────
    signal showTooltip(string text, real centreX)
    signal hideTooltip()

    HoverHandler { id: hoverHandler }

    Timer {
        id: tipDelay
        interval: 500
        running:  hoverHandler.hovered && !launchAnim.running
        repeat:   false
        onTriggered: root.showTooltip(root.appName, root.width / 2)
    }
    Connections {
        target: hoverHandler
        function onHoveredChanged() {
            if (!hoverHandler.hovered) root.hideTooltip()
        }
    }

    // ── Click / activate ─────────────────────────────────────────────────────
    signal tapped()
    onTapped: launchAnim.start()

    // ── Launch animation ─────────────────────────────────────────────────────
    SequentialAnimation {
        id: launchAnim
        NumberAnimation {
            target: root; property: "scale"
            from: root.targetScale; to: root.targetScale * 0.82
            duration: 80; easing.type: Easing.InQuad
        }
        NumberAnimation {
            target: root; property: "scale"
            to: root.targetScale * 1.15
            duration: 120; easing.type: Easing.OutQuad
        }
        NumberAnimation {
            target: root; property: "scale"
            to: root.targetScale
            duration: 180; easing.type: Easing.OutBounce
        }
    }
}
