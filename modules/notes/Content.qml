pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.Config
import Caelestia.I18n
import Caelestia.Models
import qs.components
import qs.components.containers
import qs.components.controls
import qs.services
import qs.utils

Item {
    id: root

    required property ScreenState screenState

    readonly property string vaultPath: `${Paths.home}/Documents/Obsidian/Drawer`
    property string activeFilePath: ""
    readonly property string activeFileBaseName: activeFilePath ? activeFilePath.split("/").pop().replace(/\.md$/, "") : ""
    property bool loadingFile: false
    property string saveStatusText: Tr.tr("Ready")

    readonly property bool isInputFocused: editor.activeFocus

    function initVault(): void {
        Quickshell.execDetached(["mkdir", "-p", root.vaultPath]);
    }

    function selectNote(path: string): void {
        if (root.activeFilePath === path)
            return;
        if (saveTimer.running) {
            saveTimer.stop();
            if (root.activeFilePath && !root.loadingFile)
                fileView.setText(editor.text);
        }
        root.activeFilePath = path;
    }

    function createNote(): void {
        root.initVault();
        const ts = Qt.formatDateTime(new Date(), "yyyyMMdd_hhmmss");
        const name = `note_${ts}.md`;
        const fullPath = `${root.vaultPath}/${name}`;
        const initialContent = `# Note ${ts}\n\n`;
        Quickshell.execDetached(["sh", "-c", "printf '%s\\n' \"$1\" > \"$2\"", "--", initialContent, fullPath]);
        root.activeFilePath = fullPath;
        root.loadingFile = true;
        editor.text = initialContent;
        root.loadingFile = false;
        root.saveStatusText = Tr.tr("Created");
    }

    function deleteCurrentNote(): void {
        if (!root.activeFilePath)
            return;
        const toDelete = root.activeFilePath;
        Quickshell.execDetached(["rm", "-f", toDelete]);
        root.activeFilePath = "";
        editor.text = "";
        root.saveStatusText = Tr.tr("Deleted");
    }

    function copySnippet(): void {
        if (editor.text) {
            Quickshell.execDetached(["wl-copy", editor.text]);
            root.saveStatusText = Tr.tr("Copied to clipboard!");
        }
    }

    Component.onCompleted: {
        root.initVault();
    }

    FileView {
        id: fileView

        path: root.activeFilePath
        printErrors: false
        onLoaded: {
            root.loadingFile = true;
            editor.text = text();
            root.loadingFile = false;
            root.saveStatusText = Tr.tr("Loaded");
        }
    }

    Timer {
        id: saveTimer

        interval: 500
        repeat: false
        onTriggered: {
            if (root.activeFilePath && !root.loadingFile) {
                fileView.setText(editor.text);
                root.saveStatusText = Tr.tr("Saved");
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Tokens.spacing.medium

        // Action row
        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            StyledText {
                text: root.saveStatusText
                font: Tokens.font.label.medium
                color: Colours.palette.m3outline
            }

            Item {
                Layout.fillWidth: true
            }

            IconButton {
                icon: "content_copy"
                type: IconButton.Tonal
                font: Tokens.font.icon.small
                onClicked: root.copySnippet()
            }

            IconButton {
                icon: "add"
                type: IconButton.Filled
                font: Tokens.font.icon.small
                onClicked: root.createNote()
            }

            IconButton {
                icon: "delete"
                type: IconButton.Text
                font: Tokens.font.icon.small
                enabled: root.activeFilePath !== ""
                onClicked: root.deleteCurrentNote()
            }
        }

        // Note Selector Chips
        Item {
            Layout.fillWidth: true
            implicitHeight: 34

            StyledListView {
                id: chipListView

                anchors.fill: parent
                orientation: ListView.Horizontal
                spacing: Tokens.spacing.small
                clip: true

                model: FileSystemModel {
                    id: fsModel

                    path: root.vaultPath
                    nameFilters: ["*.md"]
                    sortReverse: true
                }

                delegate: Item {
                    id: chip

                    required property FileSystemEntry modelData
                    required property int index

                    width: chipLabel.implicitWidth + Tokens.padding.medium * 2
                    height: 32

                    readonly property bool isCurrent: root.activeFilePath === chip.modelData.path

                    Component.onCompleted: {
                        if (root.activeFilePath === "" && chip.index === 0)
                            root.selectNote(chip.modelData.path);
                    }

                    StyledRect {
                        anchors.fill: parent
                        radius: Tokens.rounding.full
                        color: chip.isCurrent ? Colours.palette.m3primaryContainer : Colours.tPalette.m3surfaceContainerHigh
                        border.color: chip.isCurrent ? Colours.palette.m3primary : Colours.palette.m3outlineVariant
                        border.width: chip.isCurrent ? 1 : 0

                        StateLayer {
                            anchors.fill: parent
                            radius: Tokens.rounding.full
                            onClicked: root.selectNote(chip.modelData.path)
                        }

                        StyledText {
                            id: chipLabel

                            anchors.centerIn: parent
                            text: chip.modelData.baseName
                            font: Tokens.font.label.medium
                            color: chip.isCurrent ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurfaceVariant
                        }
                    }
                }

                StyledText {
                    anchors.centerIn: parent
                    visible: chipListView.count === 0
                    text: Tr.tr("No notes yet. Click '+' to create one.")
                    font: Tokens.font.label.medium
                    color: Colours.palette.m3outline
                }
            }
        }

        // Editor Area
        StyledRect {
            Layout.fillWidth: true
            Layout.fillHeight: true

            color: Colours.tPalette.m3surfaceContainerLow
            radius: Tokens.rounding.large
            border.color: editor.activeFocus ? Colours.palette.m3primary : Colours.palette.m3outlineVariant
            border.width: editor.activeFocus ? 2 : 1

            StyledFlickable {
                id: flickable

                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                contentWidth: width
                contentHeight: Math.max(height, editor.contentHeight + 20)
                clip: true

                StyledScrollBar.vertical: StyledScrollBar {
                    flickable: flickable
                }

                TextEdit {
                    id: editor

                    width: flickable.width
                    wrapMode: TextEdit.Wrap
                    selectByMouse: true
                    font: Tokens.font.body.medium
                    color: Colours.palette.m3onSurface
                    selectionColor: Qt.alpha(Colours.palette.m3primary, 0.4)
                    selectedTextColor: Colours.palette.m3onSurface

                    onTextChanged: {
                        if (!root.loadingFile && root.activeFilePath) {
                            root.saveStatusText = Tr.tr("Saving...");
                            saveTimer.restart();
                        }
                    }

                    Keys.onEscapePressed: {
                        focus = false;
                    }
                }
            }
        }

        // Bottom Status Bar
        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.medium

            StyledText {
                text: root.saveStatusText
                font: Tokens.font.label.small
                color: Colours.palette.m3outline
            }

            StyledText {
                text: `${editor.text.length} chars`
                font: Tokens.font.label.small
                color: Colours.palette.m3outline
            }

            Item {
                Layout.fillWidth: true
            }

            StyledText {
                text: root.activeFileBaseName ? `${root.activeFileBaseName}.md` : ""
                font: Tokens.font.label.small
                color: Colours.palette.m3outline
                elide: Text.ElideLeft
            }
        }
    }
}
