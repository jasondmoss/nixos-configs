import QtQuick
import QtQuick.Controls
import org.kde.plasmadock 1.0

LayerShellWindow {
    id: root

    // ── Edge / orientation ───────────────────────────────────────────────────
    edge:     appModelInstance.dockEdge
    dockSize: 112

    readonly property bool isVertical: edge === LayerShellWindow.Left
                                    || edge === LayerShellWindow.Right
    readonly property bool isLeftEdge: edge === LayerShellWindow.Left

    // exclusiveZone tracks the pill's visual thickness plus margin
    exclusiveZone: isVertical ? 80 : 80

    color: "transparent"

    readonly property int dockBodyHeight: 72   // pill thickness (same both axes)
    readonly property int iconSize:       dockBodyHeight - 20

    // ── Tooltip state ────────────────────────────────────────────────────────
    property string tooltipText:    ""
    property real   tooltipX:       0   // position on primary axis
    property real   tooltipY:       0
    property bool   tooltipVisible: false

    // ── Drag state ───────────────────────────────────────────────────────────
    property int  dragSourceIndex: -1
    property bool dragActive:      false

    // ── Dodge state ──────────────────────────────────────────────────────────
    property bool cursorAtEdge: false

    readonly property bool shouldDodge:
        appModelInstance.dodgeEnabled
        && dodgeManager.overlapping
        && !cursorAtEdge

    property real dodgeOffset: 0
    Behavior on dodgeOffset {
        NumberAnimation { duration: 220; easing.type: Easing.InOutCubic }
    }
    onShouldDodgeChanged: {
        if (isVertical)
            dodgeOffset = shouldDodge ? -(dockBodyHeight + 12) : 0
        else
            dodgeOffset = shouldDodge ?  (dockBodyHeight + 12) : 0
    }

    // ── Context menu state ───────────────────────────────────────────────────
    property int  contextMenuIndex:    -1
    property bool contextMenuIsPinned: false

    // ── Instances ────────────────────────────────────────────────────────────
    AppModel    { id: appModelInstance }
    DodgeManager {
        id: dodgeManager
    }

    onLayerShellReady: {
        if (appModelInstance.dodgeEnabled) {
            var s = Qt.application.screens[0]
            dodgeManager.start(
                s.width, s.height,
                root.dockSize,
                root.edge)
        }
    }

    Item { id: rootItem; anchors.fill: parent }

    // ── Dodge edge detector ──────────────────────────────────────────────────
    // A thin strip at the screen edge re-shows the dock while a window covers it.
    HoverHandler {
        id: edgeHoverHandler
        // The dock window fills the edge strip — bottom few px is near screen edge
        onHoveredChanged: root.cursorAtEdge = hovered
    }

    // ── Tooltip ──────────────────────────────────────────────────────────────
    Rectangle {
        id: tooltip
        visible:      root.tooltipVisible && root.tooltipText !== "" && !root.dragActive
        width:        tipLabel.implicitWidth + 16
        height:       tipLabel.implicitHeight + 8
        radius:       4
        color:        Qt.rgba(0.08, 0.08, 0.10, 0.92)
        border.color: Qt.rgba(1, 1, 1, 0.12)
        border.width: 1
        z:            100

        // Horizontal: centred above pill
        // Vertical left: to the right of pill at icon's vertical centre
        x: root.isVertical
            ? root.dockBodyHeight + 4
            : Math.max(0, Math.min(root.tooltipX - width / 2, root.width - width))
        y: root.isVertical
            ? root.tooltipY - height / 2
            : root.height - root.dockBodyHeight - height - 4

        Text {
            id: tipLabel
            anchors.centerIn: parent
            text:             root.tooltipText
            color:            "#ffffff"
            font.pixelSize:   12
        }
    }

    // ── Context menu ─────────────────────────────────────────────────────────
    Menu {
        id: contextMenu
        MenuItem {
            text: root.contextMenuIsPinned ? "Unpin from Dock" : "Pin to Dock"
            onTriggered: {
                if (root.contextMenuIsPinned)
                    appModelInstance.unpinApp(root.contextMenuIndex)
                else
                    appModelInstance.pinApp(
                        appModelInstance.data(
                            appModelInstance.index(root.contextMenuIndex, 0), 257))
            }
        }
        MenuItem {
            text: "Launch"
            onTriggered: appModelInstance.launch(root.contextMenuIndex)
        }
        MenuSeparator {}
        MenuItem {
            text: root.isVertical ? "Move to Bottom" : "Move to Left"
            onTriggered: {
                var newEdge = root.isVertical ? 1 : 2
                appModelInstance.setDockEdge(newEdge)
                // Re-start dodge with updated dock rect if enabled
                if (appModelInstance.dodgeEnabled) {
                    var s = Qt.application.screens[0]
                    dodgeManager.start(s.width, s.height, root.dockSize, newEdge)
                }
            }
        }
        MenuItem {
            text: appModelInstance.dodgeEnabled ? "Disable Dodge" : "Enable Dodge"
            onTriggered: {
                appModelInstance.setDodgeEnabled(!appModelInstance.dodgeEnabled)
                if (appModelInstance.dodgeEnabled && !dodgeManager.overlapping) {
                    var s = Qt.application.screens[0]
                    dodgeManager.start(s.width, s.height, root.dockSize, root.edge)
                }
            }
        }
    }

    // ── Dock content — translated for dodge animation ─────────────────────
    Item {
        id: dockContent
        anchors.fill: parent

        transform: Translate {
            x: root.isVertical ? root.dodgeOffset : 0
            y: root.isVertical ? 0 : root.dodgeOffset
        }

        // ── Pill ─────────────────────────────────────────────────────────────
        Rectangle {
            id: dockBody
            radius: root.isVertical
                    ? (root.dockBodyHeight - 8) / 2
                    : (root.dockBodyHeight - 8) / 2
            color:        Qt.rgba(0.08, 0.08, 0.10, 0.72)
            border.color: Qt.rgba(1, 1, 1, 0.10)
            border.width: 1

            states: [
                State {
                    name: "horizontal"
                    when: !root.isVertical
                    AnchorChanges {
                        target: dockBody
                        anchors.bottom:           dockContent.bottom
                        anchors.horizontalCenter: dockContent.horizontalCenter
                        anchors.left:  undefined
                        anchors.verticalCenter: undefined
                    }
                    PropertyChanges {
                        target: dockBody
                        anchors.bottomMargin: 8
                        width:  iconFlow.implicitWidth  + 24
                        height: root.dockBodyHeight - 8
                    }
                },
                State {
                    name: "vertical"
                    when: root.isVertical
                    AnchorChanges {
                        target: dockBody
                        anchors.left:             dockContent.left
                        anchors.verticalCenter:   dockContent.verticalCenter
                        anchors.bottom: undefined
                        anchors.horizontalCenter: undefined
                    }
                    PropertyChanges {
                        target: dockBody
                        anchors.leftMargin: 8
                        width:  root.dockBodyHeight - 8
                        height: iconFlow.implicitHeight + 24
                    }
                }
            ]
        }

        // ── Icon flow ─────────────────────────────────────────────────────────
        Flow {
            id: iconFlow
            flow:         root.isVertical ? Flow.TopToBottom : Flow.LeftToRight
            spacing:      6
            padding:      8
            leftPadding:  root.isVertical ? 0 : 8
            rightPadding: root.isVertical ? 0 : 8

            states: [
                State {
                    name: "horizontal"
                    when: !root.isVertical
                    AnchorChanges {
                        target: iconFlow
                        anchors.bottom:           dockContent.bottom
                        anchors.horizontalCenter: dockContent.horizontalCenter
                        anchors.left:  undefined
                        anchors.verticalCenter: undefined
                    }
                    PropertyChanges {
                        target: iconFlow
                        anchors.bottomMargin: 8 + (root.dockBodyHeight - 8 - root.iconSize) / 2
                    }
                },
                State {
                    name: "vertical"
                    when: root.isVertical
                    AnchorChanges {
                        target: iconFlow
                        anchors.left:           dockContent.left
                        anchors.verticalCenter: dockContent.verticalCenter
                        anchors.bottom: undefined
                        anchors.horizontalCenter: undefined
                    }
                    PropertyChanges {
                        target: iconFlow
                        anchors.leftMargin: 8 + (root.dockBodyHeight - 8 - root.iconSize) / 2
                    }
                }
            ]

            Repeater {
                model: appModelInstance
                delegate: Item {
                    id: delegate
                    width:  model.isSeparator ? (root.isVertical ? root.iconSize : 9)
                                              : root.iconSize
                    height: model.isSeparator ? (root.isVertical ? 9 : root.iconSize)
                                              : root.iconSize

                    // Track both axes — pass the relevant one to DockIcon
                    property real localMouseX: -999
                    property real localMouseY: -999
                    HoverHandler {
                        onPointChanged: {
                            delegate.localMouseX = point.position.x
                            delegate.localMouseY = point.position.y
                        }
                        onHoveredChanged: {
                            if (!hovered) {
                                delegate.localMouseX = -999
                                delegate.localMouseY = -999
                            }
                        }
                    }

                    // Separator line — rotates with orientation
                    Rectangle {
                        visible:          model.isSeparator
                        anchors.centerIn: parent
                        width:  root.isVertical ? parent.width * 0.7 : 1
                        height: root.isVertical ? 1 : parent.height * 0.7
                        color:  Qt.rgba(1, 1, 1, 0.18)
                    }

                    DockIcon {
                        id: icon
                        visible:     !model.isSeparator
                        isVertical:  root.isVertical
                        anchors.bottom: root.isVertical ? undefined : parent.bottom
                        anchors.right:  root.isVertical ? parent.right : undefined
                        baseSize:    root.iconSize
                        iconName:    model.iconName
                        appName:     model.name
                        appIndex:    index
                        isRunning:   model.isRunning
                        isPinned:    model.isPinned

                        // Pass the relevant axis to DockIcon's distance calc
                        dockMouseX:  root.dragActive ? -999
                                     : (root.isVertical ? delegate.localMouseY
                                                        : delegate.localMouseX)
                        iconCentreX: root.iconSize / 2

                        opacity: (root.dragActive && root.dragSourceIndex === index)
                                 ? 0.35 : 1.0
                        Behavior on opacity { NumberAnimation { duration: 100 } }

                        onShowTooltip: function(text, cx) {
                            root.tooltipText = text
                            if (root.isVertical) {
                                root.tooltipY = icon.mapToItem(rootItem, 0, cx).y
                            } else {
                                root.tooltipX = icon.mapToItem(rootItem, cx, 0).x
                            }
                            root.tooltipVisible = true
                        }
                        onHideTooltip: root.tooltipVisible = false
                    }

                    // ── Mouse: click + drag ───────────────────────────────────
                    MouseArea {
                        id: dragMouse
                        anchors.fill:            parent
                        enabled:                 !model.isSeparator
                        propagateComposedEvents: true
                        preventStealing:         false

                        property real pressCoord: 0

                        onClicked: (mouse) => {
                            if (mouse.button === Qt.LeftButton && !root.dragActive) {
                                icon.tapped()
                                appModelInstance.activateOrLaunch(index)
                            }
                        }

                        onPressed: (mouse) => {
                            pressCoord = root.isVertical ? mouse.y : mouse.x
                        }

                        onPositionChanged: (mouse) => {
                            const coord = root.isVertical ? mouse.y : mouse.x
                            if (model.isPinned && !root.dragActive
                                    && Math.abs(coord - pressCoord) > 6) {
                                root.dragActive      = true
                                root.dragSourceIndex = index
                                root.tooltipVisible  = false
                            }
                            if (!root.dragActive) return

                            // Map cursor into flow coordinate space
                            const cursorInFlow = root.isVertical
                                ? dragMouse.mapToItem(iconFlow, 0, mouse.y).y
                                : dragMouse.mapToItem(iconFlow, mouse.x, 0).x
                            const slotSize = root.iconSize + 6

                            if (root.dragSourceIndex > 0) {
                                const prevMid = (root.dragSourceIndex - 1) * slotSize
                                                + slotSize * 0.3 + iconFlow.padding
                                if (cursorInFlow < prevMid) {
                                    appModelInstance.moveApp(root.dragSourceIndex,
                                                             root.dragSourceIndex - 1)
                                    root.dragSourceIndex--
                                    return
                                }
                            }

                            const sepIdx = appModelInstance.count
                            if (root.dragSourceIndex < sepIdx - 1) {
                                const nextMid = (root.dragSourceIndex + 1) * slotSize
                                                + slotSize * 0.7 + iconFlow.padding
                                if (cursorInFlow > nextMid) {
                                    appModelInstance.moveApp(root.dragSourceIndex,
                                                             root.dragSourceIndex + 1)
                                    root.dragSourceIndex++
                                    return
                                }
                            }
                        }

                        onReleased: {
                            root.dragActive      = false
                            root.dragSourceIndex = -1
                        }
                    }

                    // ── Right-click ───────────────────────────────────────────
                    TapHandler {
                        acceptedButtons: Qt.RightButton
                        onTapped: {
                            root.contextMenuIndex    = index
                            root.contextMenuIsPinned = model.isPinned
                            contextMenu.popup()
                        }
                    }
                }
            }
        }
    }
}
