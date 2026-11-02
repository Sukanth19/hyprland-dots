pragma ComponentBehavior: Bound
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io

Item {
    id: root
    property string query: ""
    property int maxRecent: 24
    property list<string> recent: []
    property string lastCopied: ""

    // Entries look like "😀 grinning face face smile happy ..."
    function emojiOf(entry) { return entry.match(/^\s*(\S+)/)?.[1] ?? ""; }
    function nameOf(entry) { return entry.replace(/^\s*\S+\s*/, ""); }

    property var results: query.trim().length > 0 ? Emojis.fuzzyQuery(query) : Emojis.list

    function pick(entry) {
        const e = emojiOf(entry);
        Quickshell.execDetached(["wl-copy", e]);
        root.recent = [entry, ...root.recent.filter(r => r !== entry)].slice(0, root.maxRecent);
        recentFile.setText(root.recent.join("\n"));
        root.lastCopied = e;
        copiedTimer.restart();
    }

    onFocusChanged: (focus) => { if (focus) searchField.forceActiveFocus() }

    FileView {
        id: recentFile
        path: FileUtils.trimFileProtocol(`${Directories.state}/user/recent_emojis.txt`)
        printErrors: false
        onLoaded: root.recent = text().split("\n").filter(l => l.trim().length > 0).slice(0, root.maxRecent)
    }

    Timer { id: copiedTimer; interval: 1500 }

    component EmojiCell: RippleButton {
        id: cell
        required property string entry
        property real size: 44
        implicitWidth: size
        implicitHeight: size
        buttonRadius: Appearance.rounding.small
        colBackground: "transparent"
        colBackgroundHover: Appearance.colors.colLayer2Hover
        colRipple: Appearance.colors.colLayer2Active
        downAction: () => root.pick(entry)
        StyledToolTip { text: root.nameOf(cell.entry).split(" ").slice(0, 4).join(" ") }
        contentItem: Text {
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: root.emojiOf(cell.entry)
            font.pixelSize: cell.size * 0.6
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        // Search
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 40
            radius: Appearance.rounding.full
            color: Appearance.colors.colLayer2

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 8
                MaterialSymbol {
                    text: "search"
                    iconSize: Appearance.font.pixelSize.large
                    color: Appearance.colors.colSubtext
                }
                StyledTextInput {
                    id: searchField
                    Layout.fillWidth: true
                    color: Appearance.colors.colOnLayer2
                    font.pixelSize: Appearance.font.pixelSize.small
                    clip: true
                    onTextChanged: root.query = text
                    Keys.onPressed: (event) => {
                        if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && root.results.length > 0) {
                            root.pick(root.results[0]);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Escape && text.length > 0) {
                            text = "";
                            event.accepted = true;
                        }
                    }
                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: searchField.text.length === 0
                        text: Translation.tr("Search emojis")
                        color: Appearance.colors.colSubtext
                        font.pixelSize: Appearance.font.pixelSize.small
                    }
                }
            }
        }

        // Recent
        ColumnLayout {
            Layout.fillWidth: true
            visible: root.query.length === 0 && root.recent.length > 0
            spacing: 2
            StyledText {
                text: Translation.tr("Recent")
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
                Layout.leftMargin: 4
            }
            Flow {
                Layout.fillWidth: true
                spacing: 0
                Repeater {
                    model: root.recent.slice(0, Math.max(1, Math.floor(parent.width / 44)) * 2)
                    delegate: EmojiCell {
                        required property string modelData
                        entry: modelData
                    }
                }
            }
            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 4
                implicitHeight: 1
                color: Appearance.colors.colLayer2
            }
        }

        // All / results
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            PagePlaceholder {
                anchors.fill: parent
                shown: root.results.length === 0
                icon: "sentiment_dissatisfied"
                title: Translation.tr("No emojis found")
                description: ""
            }

            GridView {
                id: grid
                anchors.fill: parent
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                property int columns: Math.max(1, Math.floor(width / 44))
                cellWidth: width / columns
                cellHeight: 44
                model: root.results
                cacheBuffer: 400
                delegate: Item {
                    required property string modelData
                    width: grid.cellWidth
                    height: grid.cellHeight
                    EmojiCell {
                        anchors.centerIn: parent
                        entry: parent.modelData
                    }
                }
                ScrollBar.vertical: StyledScrollBar {}
            }
        }
    }

    // "Copied" toast
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 16
        implicitWidth: toastRow.implicitWidth + 28
        implicitHeight: 40
        radius: Appearance.rounding.full
        color: Appearance.colors.colPrimary
        opacity: copiedTimer.running ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 150 } }
        RowLayout {
            id: toastRow
            anchors.centerIn: parent
            spacing: 6
            Text { text: root.lastCopied; font.pixelSize: 18 }
            StyledText {
                text: Translation.tr("Copied")
                color: Appearance.colors.colOnPrimary
                font.pixelSize: Appearance.font.pixelSize.small
            }
        }
    }
}
