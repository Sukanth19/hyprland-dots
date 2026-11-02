import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets

// Workspace switcher: plain numbers, with a pill that slides to the active one
Item {
    id: root

    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.QsWindow.window?.screen)
    readonly property int shownCount: Config.options.bar.workspaces.shown
    readonly property int activeId: monitor?.activeWorkspace?.id ?? 1
    readonly property int groupOffset: Math.floor((activeId - 1) / shownCount) * shownCount
    readonly property int activeIndex: (activeId - 1) % shownCount
    readonly property var occupied: Hyprland.workspaces.values.map(ws => ws.id)

    readonly property real itemWidth: 28
    readonly property real activeWidth: 46
    readonly property real itemHeight: 24

    implicitWidth: activeWidth + itemWidth * (shownCount - 1)
    implicitHeight: itemHeight

    function label(id) {
        const map = Config.options.bar.workspaces.numberMap;
        return (map && map[id - 1]) ? map[id - 1] : `${id}`;
    }

    // Sliding active pill
    Rectangle {
        x: root.activeIndex * root.itemWidth
        anchors.verticalCenter: parent.verticalCenter
        width: root.activeWidth
        height: root.itemHeight
        radius: height / 2
        color: Appearance.colors.colPrimary
        Behavior on x {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }
    }

    Row {
        anchors.verticalCenter: parent.verticalCenter
        Repeater {
            model: root.shownCount
            delegate: MouseArea {
                id: button
                required property int index
                readonly property int wsId: root.groupOffset + index + 1
                readonly property bool active: index === root.activeIndex
                readonly property bool hasWindows: root.occupied.includes(wsId)

                width: active ? root.activeWidth : root.itemWidth
                height: root.itemHeight
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: event => {
                    if (event.button === Qt.RightButton)
                        GlobalStates.overviewOpen = !GlobalStates.overviewOpen;
                    else
                        Hyprland.dispatch(`hl.dsp.focus({workspace = ${button.wsId}})`);
                }
                Behavior on width {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }

                // Hover highlight
                Rectangle {
                    anchors.centerIn: parent
                    width: root.itemHeight
                    height: root.itemHeight
                    radius: height / 2
                    color: Appearance.colors.colLayer1Hover
                    opacity: (button.containsMouse && !button.active) ? 1 : 0
                    Behavior on opacity {
                        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                    }
                }

                StyledText {
                    anchors.centerIn: parent
                    text: root.label(button.wsId)
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.DemiBold
                    color: button.active ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer1
                    // empty workspaces are dimmed
                    opacity: (button.active || button.hasWindows) ? 1 : 0.45
                    Behavior on color {
                        animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                    }
                }
            }
        }
    }

    // Scroll to switch workspace
    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            if (event.angleDelta.y < 0)
                Hyprland.dispatch(`hl.dsp.focus({workspace = "r+1"})`);
            else if (event.angleDelta.y > 0)
                Hyprland.dispatch(`hl.dsp.focus({workspace = "r-1"})`);
        }
    }
}
