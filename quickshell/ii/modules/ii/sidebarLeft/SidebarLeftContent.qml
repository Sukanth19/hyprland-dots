import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Qt.labs.synchronizer

Item {
    id: root
    required property var scopeRoot
    property int sidebarPadding: 10
    anchors.fill: parent
    property bool aiChatEnabled: Config.options.policies.ai !== 0
    property bool translatorEnabled: Config.options.sidebar.translator.enable
    property bool animeEnabled: Config.options.policies.weeb !== 0
    property bool animeCloset: Config.options.policies.weeb === 2
    property var tabButtonList: [
        {"icon": "music_note", "name": Translation.tr("Media")},
        {"icon": "mood", "name": Translation.tr("Emoji")},
        {"icon": "monitoring", "name": Translation.tr("System")},
        ...(root.aiChatEnabled ? [{"icon": "neurology", "name": Translation.tr("Intelligence")}] : []),
        ...(root.translatorEnabled ? [{"icon": "translate", "name": Translation.tr("Translator")}] : []),
        ...((root.animeEnabled && !root.animeCloset) ? [{"icon": "bookmark_heart", "name": Translation.tr("Anime")}] : [])
    ]
    property int tabCount: swipeView.count

    // Open the sidebar straight on the Emoji tab (Super + .)
    function toggleTab(name) {
        if (GlobalStates.sidebarLeftOpen && root.tabButtonList[swipeView.currentIndex]?.name === name)
            GlobalStates.sidebarLeftOpen = false;
        else
            root.openTab(name);
    }
    property int pendingTab: -1
    function openTab(name) {
        const i = root.tabButtonList.findIndex(t => t.name === name);
        if (i < 0) return;
        root.pendingTab = i;
        GlobalStates.sidebarLeftOpen = true;
        switchTimer.restart();
    }
    Timer {
        id: switchTimer
        interval: 60
        onTriggered: {
            tabBar.setCurrentIndex(root.pendingTab);
            swipeView.setCurrentIndex(root.pendingTab);
            focusTimer.restart();
        }
    }
    Timer {
        id: focusTimer
        interval: 250
        onTriggered: root.focusActiveItem()
    }

    function focusActiveItem() {
        swipeView.currentItem.forceActiveFocus()
    }

    Keys.onPressed: (event) => {
        if (event.modifiers === Qt.ControlModifier) {
            if (event.key === Qt.Key_PageDown) {
                swipeView.incrementCurrentIndex()
                event.accepted = true;
            }
            else if (event.key === Qt.Key_PageUp) {
                swipeView.decrementCurrentIndex()
                event.accepted = true;
            }
        }
    }

    ColumnLayout {
        anchors {
            fill: parent
            margins: sidebarPadding
        }
        spacing: sidebarPadding

        Toolbar {
            visible: tabButtonList.length > 0
            Layout.alignment: Qt.AlignHCenter
            enableShadow: false
            ToolbarTabBar {
                id: tabBar
                Layout.alignment: Qt.AlignHCenter
                tabButtonList: root.tabButtonList
                currentIndex: swipeView.currentIndex
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            implicitWidth: swipeView.implicitWidth
            implicitHeight: swipeView.implicitHeight
            radius: Appearance.rounding.normal
            color: Appearance.colors.colLayer1

            SwipeView { // Content pages
                id: swipeView
                anchors.fill: parent
                spacing: 10
                currentIndex: tabBar.currentIndex

                clip: true
                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: swipeView.width
                        height: swipeView.height
                        radius: Appearance.rounding.small
                    }
                }

                contentChildren: [
                    media.createObject(),
                    emojiPicker.createObject(),
                    systemMonitor.createObject(),
                    ...(root.aiChatEnabled ? [aiChat.createObject()] : []),
                    ...(root.translatorEnabled ? [translator.createObject()] : []),
                    ...((root.tabButtonList.length === 0) ? [placeholder.createObject()] : []),
                    ...(root.animeEnabled ? [anime.createObject()] : []),
                ]
            }
        }

        Component {
            id: media
            Media {}
        }
        Component {
            id: emojiPicker
            EmojiPicker {}
        }
        Component {
            id: systemMonitor
            SystemMonitor {}
        }
        Component {
            id: aiChat
            AiChat {}
        }
        Component {
            id: translator
            Translator {}
        }
        Component {
            id: anime
            Anime {}
        }
        Component {
            id: placeholder
            Item {
                StyledText {
                    anchors.centerIn: parent
                    text: root.animeCloset ? Translation.tr("Nothing") : Translation.tr("Enjoy your empty sidebar...")
                    color: Appearance.colors.colSubtext
                }
            }
        }
    }
}