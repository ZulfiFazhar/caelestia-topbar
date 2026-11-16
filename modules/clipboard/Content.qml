pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services
import qs.modules.notes as Notes

Item {
    id: root

    required property ScreenState screenState

    readonly property bool isInputFocused: root.screenState.clipboardTab === 0
        ? (clipView.item?.isInputFocused ?? false)
        : (notesView.item?.isInputFocused ?? false)

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Tokens.padding.medium
        spacing: Tokens.spacing.medium

        // Tab Selector Row
        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            IconTextButton {
                Layout.fillWidth: true
                icon: "content_paste"
                text: Tr.tr("Clipboard")
                isToggle: true
                type: TextButton.Filled
                checked: root.screenState.clipboardTab === 0
                onClicked: root.screenState.clipboardTab = 0
            }

            IconTextButton {
                Layout.fillWidth: true
                icon: "edit_note"
                text: Tr.tr("Notes")
                isToggle: true
                type: TextButton.Filled
                checked: root.screenState.clipboardTab === 1
                onClicked: root.screenState.clipboardTab = 1
            }

            IconButton {
                icon: "close"
                type: IconButton.Text
                font: Tokens.font.icon.small
                onClicked: {
                    root.screenState.clipboard = false;
                    root.screenState.notes = false;
                }
            }
        }

        // Tab Content
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Loader {
                id: clipView

                anchors.fill: parent
                visible: root.screenState.clipboardTab === 0
                active: root.screenState.clipboard
                sourceComponent: ClipboardView {
                    screenState: root.screenState
                }
            }

            Loader {
                id: notesView

                anchors.fill: parent
                visible: root.screenState.clipboardTab === 1
                active: root.screenState.clipboard
                sourceComponent: Notes.Content {
                    screenState: root.screenState
                }
            }
        }
    }
}
