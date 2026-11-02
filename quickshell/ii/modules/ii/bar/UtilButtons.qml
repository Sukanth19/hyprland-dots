import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

Item {
    id: root
    property bool borderless: Config.options.bar.borderless
    implicitWidth: rowLayout.implicitWidth + rowLayout.spacing * 2
    implicitHeight: rowLayout.implicitHeight

    // Screen recording state (red stop button while wf-recorder runs)
    property bool isRecording: false
    Process {
        id: recordCheck
        command: ["pgrep", "-x", "wf-recorder"]
        onExited: (exitCode, exitStatus) => { root.isRecording = (exitCode === 0) }
    }
    Timer {
        running: Config.options.bar.utilButtons.showScreenRecord
        interval: 1000
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!recordCheck.running) recordCheck.running = true
    }

    RowLayout {
        id: rowLayout

        spacing: 4
        anchors.centerIn: parent

        Loader {
            active: Config.options.bar.utilButtons.showScreenSnip
            visible: Config.options.bar.utilButtons.showScreenSnip
            sourceComponent: CircleUtilButton {
                Layout.alignment: Qt.AlignVCenter
                onClicked: Quickshell.execDetached(["qs", "-p", Quickshell.shellPath(""), "ipc", "call", "region", "screenshot"]);
                MaterialSymbol {
                    horizontalAlignment: Qt.AlignHCenter
                    fill: 1
                    text: "screenshot_region"
                    iconSize: Appearance.font.pixelSize.large
                    color: Appearance.colors.colOnLayer2
                }
            }
        }

        Loader {
            active: Config.options.bar.utilButtons.showScreenRecord
            visible: Config.options.bar.utilButtons.showScreenRecord
            sourceComponent: CircleUtilButton {
                Layout.alignment: Qt.AlignVCenter
                onClicked: Quickshell.execDetached([Directories.recordScriptPath])
                colBackground: root.isRecording ? Appearance.m3colors.m3error : ColorUtils.transparentize(Appearance.colors.colLayer1Hover, 1)
                colBackgroundHover: root.isRecording ? Qt.lighter(Appearance.m3colors.m3error, 1.15) : Appearance.colors.colLayer1Hover
                MaterialSymbol {
                    horizontalAlignment: Qt.AlignHCenter
                    fill: 1
                    text: root.isRecording ? "stop" : "videocam"
                    iconSize: Appearance.font.pixelSize.large
                    color: root.isRecording ? Appearance.m3colors.m3onError : Appearance.colors.colOnLayer2
                }
            }
        }

        Loader {
            active: Config.options.bar.utilButtons.showColorPicker
            visible: Config.options.bar.utilButtons.showColorPicker
            sourceComponent: CircleUtilButton {
                Layout.alignment: Qt.AlignVCenter
                onClicked: Quickshell.execDetached(["hyprpicker", "-a"])
                MaterialSymbol {
                    horizontalAlignment: Qt.AlignHCenter
                    fill: 1
                    text: "colorize"
                    iconSize: Appearance.font.pixelSize.large
                    color: Appearance.colors.colOnLayer2
                }
            }
        }

        Loader {
            active: Config.options.bar.utilButtons.showKeyboardToggle
            visible: Config.options.bar.utilButtons.showKeyboardToggle
            sourceComponent: CircleUtilButton {
                Layout.alignment: Qt.AlignVCenter
                onClicked: GlobalStates.oskOpen = !GlobalStates.oskOpen
                MaterialSymbol {
                    horizontalAlignment: Qt.AlignHCenter
                    fill: 0
                    text: "keyboard"
                    iconSize: Appearance.font.pixelSize.large
                    color: Appearance.colors.colOnLayer2
                }
            }
        }

        Loader {
            active: Config.options.bar.utilButtons.showMicToggle
            visible: Config.options.bar.utilButtons.showMicToggle
            sourceComponent: CircleUtilButton {
                Layout.alignment: Qt.AlignVCenter
                onClicked: Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_SOURCE@", "toggle"])
                MaterialSymbol {
                    horizontalAlignment: Qt.AlignHCenter
                    fill: 0
                    text: Pipewire.defaultAudioSource?.audio?.muted ? "mic_off" : "mic"
                    iconSize: Appearance.font.pixelSize.large
                    color: Appearance.colors.colOnLayer2
                }
            }
        }

        Loader {
            active: Config.options.bar.utilButtons.showDarkModeToggle
            visible: Config.options.bar.utilButtons.showDarkModeToggle
            sourceComponent: CircleUtilButton {
                Layout.alignment: Qt.AlignVCenter
                onClicked: event => {
                    if (Appearance.m3colors.darkmode) {
                        Quickshell.execDetached(["bash", "-c", `${Directories.wallpaperSwitchScriptPath} --mode light --noswitch`])
                    } else {
                        Quickshell.execDetached(["bash", "-c", `${Directories.wallpaperSwitchScriptPath} --mode dark --noswitch`])
                    }
                }
                MaterialSymbol {
                    horizontalAlignment: Qt.AlignHCenter
                    fill: 0
                    text: Appearance.m3colors.darkmode ? "light_mode" : "dark_mode"
                    iconSize: Appearance.font.pixelSize.large
                    color: Appearance.colors.colOnLayer2
                }
            }
        }

        Loader {
            active: Config.options.bar.utilButtons.showPerformanceProfileToggle
            visible: Config.options.bar.utilButtons.showPerformanceProfileToggle
            sourceComponent: CircleUtilButton {
                Layout.alignment: Qt.AlignVCenter
                onClicked: event => {
                    if (PowerProfiles.hasPerformanceProfile) {
                        switch(PowerProfiles.profile) {
                            case PowerProfile.PowerSaver: PowerProfiles.profile = PowerProfile.Balanced
                            break;
                            case PowerProfile.Balanced: PowerProfiles.profile = PowerProfile.Performance
                            break;
                            case PowerProfile.Performance: PowerProfiles.profile = PowerProfile.PowerSaver
                            break;
                        }
                    } else {
                        PowerProfiles.profile = PowerProfiles.profile == PowerProfile.Balanced ? PowerProfile.PowerSaver : PowerProfile.Balanced
                    }
                }
                MaterialSymbol {
                    horizontalAlignment: Qt.AlignHCenter
                    fill: 0
                    text: switch(PowerProfiles.profile) {
                        case PowerProfile.PowerSaver: return "energy_savings_leaf"
                        case PowerProfile.Balanced: return "airwave"
                        case PowerProfile.Performance: return "local_fire_department"
                    }
                    iconSize: Appearance.font.pixelSize.large
                    color: Appearance.colors.colOnLayer2
                }
            }
        }
    }
}
