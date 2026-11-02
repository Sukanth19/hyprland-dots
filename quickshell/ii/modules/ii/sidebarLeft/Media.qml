pragma ComponentBehavior: Bound
import qs.services
import qs.modules.common
import qs.modules.common.models
import qs.modules.common.widgets
import qs.modules.common.functions
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

Item {
    id: root
    property MprisPlayer player: MprisController.activePlayer
    property var players: MprisController.players
    property string artUrl: player?.trackArtUrl ?? ""
    property string artDir: FileUtils.trimFileProtocol(`${Directories.cache}/media/sidebarart`)
    property string artFilePath: artUrl.length > 0 ? `${artDir}/${Qt.md5(artUrl)}` : ""
    property bool downloaded: false
    property string displayedArt: downloaded && artFilePath.length > 0 ? Qt.resolvedUrl(artFilePath) : ""
    property color artColor: ColorUtils.mix((colorQuantizer?.colors[0] ?? Appearance.colors.colPrimary), Appearance.colors.colPrimaryContainer, 0.8) || Appearance.m3colors.m3secondaryContainer
    property QtObject c: AdaptedMaterialScheme { color: root.artColor }

    onArtFilePathChanged: {
        downloaded = false;
        if (artFilePath.length === 0) return;
        artDownloader.targetUrl = artUrl;
        artDownloader.targetPath = artFilePath;
        artDownloader.running = true;
    }

    Process {
        id: artDownloader
        property string targetUrl
        property string targetPath
        command: ["bash", "-c", `mkdir -p '${root.artDir}'; [ -f '${targetPath}' ] || curl -4 -sSL '${targetUrl}' -o '${targetPath}'`]
        onExited: (exitCode, exitStatus) => { root.downloaded = (exitCode === 0) }
    }

    ColorQuantizer {
        id: colorQuantizer
        source: root.displayedArt
        depth: 0
        rescaleSize: 1
    }

    Timer { // keep position ticking
        running: root.visible && (root.player?.isPlaying ?? false)
        interval: 1000
        repeat: true
        onTriggered: root.player.positionChanged()
    }

    // Blurred art background
    StyledImage {
        id: bgArt
        anchors.fill: parent
        source: root.displayedArt
        fillMode: Image.PreserveAspectCrop
        cache: false
        asynchronous: true
        visible: root.player !== null
        layer.enabled: true
        layer.effect: StyledBlurEffect { source: bgArt }
        Rectangle {
            anchors.fill: parent
            color: ColorUtils.transparentize(root.c.colLayer0, 0.25)
        }
    }

    PagePlaceholder {
        anchors.fill: parent
        shown: root.player === null
        icon: "music_off"
        title: Translation.tr("Nothing playing")
        description: Translation.tr("Start some music and it'll show up here")
    }

    component CtrlButton: RippleButton {
        property string iconName
        property real size: 40
        property bool active: false
        implicitWidth: size
        implicitHeight: size
        buttonRadius: size / 2
        colBackground: ColorUtils.transparentize(root.c.colSecondaryContainer, 1)
        colBackgroundHover: root.c.colSecondaryContainerHover
        colRipple: root.c.colSecondaryContainerActive
        contentItem: MaterialSymbol {
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            iconSize: Appearance.font.pixelSize.huge
            fill: 1
            text: parent.iconName
            color: parent.active ? root.c.colPrimary : root.c.colOnLayer0
            opacity: parent.enabled ? 1 : 0.4
        }
    }

    ColumnLayout {
        visible: root.player !== null
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        // Player switcher
        Flow {
            Layout.fillWidth: true
            visible: root.players.length > 1
            spacing: 6
            Repeater {
                model: root.players
                delegate: RippleButton {
                    required property MprisPlayer modelData
                    toggled: modelData === root.player
                    implicitHeight: 30
                    implicitWidth: chipText.implicitWidth + 24
                    buttonRadius: 15
                    colBackground: root.c.colSecondaryContainer
                    colBackgroundToggled: root.c.colPrimary
                    downAction: () => { MprisController.trackedPlayer = modelData }
                    contentItem: StyledText {
                        id: chipText
                        horizontalAlignment: Text.AlignHCenter
                        text: parent.modelData.identity || "Player"
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: parent.toggled ? root.c.colOnPrimary : root.c.colOnSecondaryContainer
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }

        // Album art
        Rectangle {
            id: artBox
            Layout.alignment: Qt.AlignHCenter
            property real side: Math.min(root.width - 64, root.height * 0.45)
            implicitWidth: side
            implicitHeight: side
            radius: Appearance.rounding.normal
            color: ColorUtils.transparentize(root.c.colLayer1, 0.4)
            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle { width: artBox.width; height: artBox.height; radius: artBox.radius }
            }
            MaterialSymbol {
                anchors.centerIn: parent
                visible: root.displayedArt.length === 0
                text: "music_note"
                iconSize: artBox.side * 0.4
                color: root.c.colSubtext
            }
            StyledImage {
                anchors.fill: parent
                source: root.displayedArt
                fillMode: Image.PreserveAspectCrop
                cache: false
                antialiasing: true
            }
        }

        // Title / artist
        ColumnLayout {
            Layout.fillWidth: true
            Layout.topMargin: 6
            spacing: 2
            StyledText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                font.pixelSize: Appearance.font.pixelSize.larger
                font.weight: Font.Medium
                color: root.c.colOnLayer0
                text: StringUtils.cleanMusicTitle(root.player?.trackTitle) || Translation.tr("Untitled")
                animateChange: true
            }
            StyledText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                font.pixelSize: Appearance.font.pixelSize.small
                color: root.c.colSubtext
                text: [root.player?.trackArtist, root.player?.trackAlbum].filter(s => s && s.length > 0).join(" • ")
                animateChange: true
            }
        }

        // Seek bar
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            Loader {
                Layout.fillWidth: true
                active: root.player?.canSeek ?? false
                visible: active
                sourceComponent: StyledSlider {
                    configuration: StyledSlider.Configuration.Wavy
                    highlightColor: root.c.colPrimary
                    trackColor: root.c.colSecondaryContainer
                    handleColor: root.c.colPrimary
                    usePercentTooltip: false
                    tooltipContent: StringUtils.friendlyTimeForSeconds(value * (root.player?.length ?? 0))
                    value: root.player?.length > 0 ? root.player.position / root.player.length : 0
                    onMoved: root.player.position = value * root.player.length
                }
            }
            Loader {
                Layout.fillWidth: true
                active: !(root.player?.canSeek ?? false)
                visible: active
                sourceComponent: StyledProgressBar {
                    wavy: root.player?.isPlaying ?? false
                    highlightColor: root.c.colPrimary
                    trackColor: root.c.colSecondaryContainer
                    value: root.player?.length > 0 ? root.player.position / root.player.length : 0
                }
            }
            RowLayout {
                Layout.fillWidth: true
                StyledText {
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: root.c.colSubtext
                    text: StringUtils.friendlyTimeForSeconds(root.player?.position ?? 0)
                }
                Item { Layout.fillWidth: true }
                StyledText {
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: root.c.colSubtext
                    text: StringUtils.friendlyTimeForSeconds(root.player?.length ?? 0)
                }
            }
        }

        // Controls
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 8
            CtrlButton {
                iconName: "shuffle"
                enabled: MprisController.shuffleSupported
                active: MprisController.hasShuffle
                downAction: () => MprisController.setShuffle(!MprisController.hasShuffle)
            }
            CtrlButton {
                iconName: "skip_previous"
                size: 48
                enabled: MprisController.canGoPrevious
                downAction: () => MprisController.previous()
            }
            RippleButton {
                property real size: 64
                implicitWidth: size
                implicitHeight: size
                buttonRadius: root.player?.isPlaying ? Appearance.rounding.normal : size / 2
                colBackground: root.c.colPrimary
                colBackgroundHover: root.c.colPrimaryHover
                colRipple: root.c.colPrimaryActive
                downAction: () => MprisController.togglePlaying()
                contentItem: MaterialSymbol {
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    iconSize: 32
                    fill: 1
                    color: root.c.colOnPrimary
                    text: root.player?.isPlaying ? "pause" : "play_arrow"
                }
            }
            CtrlButton {
                iconName: "skip_next"
                size: 48
                enabled: MprisController.canGoNext
                downAction: () => MprisController.next()
            }
            CtrlButton {
                iconName: MprisController.loopState === MprisLoopState.Track ? "repeat_one" : "repeat"
                enabled: MprisController.loopSupported
                active: MprisController.loopState !== MprisLoopState.None
                downAction: () => MprisController.setLoopState(
                    MprisController.loopState === MprisLoopState.None ? MprisLoopState.Playlist
                    : MprisController.loopState === MprisLoopState.Playlist ? MprisLoopState.Track
                    : MprisLoopState.None)
            }
        }

        Item { Layout.fillHeight: true }
    }
}
