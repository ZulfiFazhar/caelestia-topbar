pragma ComponentBehavior: Bound

import QtQuick
import Caelestia
import Caelestia.Config
import qs.components

Item {
    id: root

    required property ScreenState screenState

    readonly property bool shouldBeActive: screenState.clipboard
    property real offsetScale: shouldBeActive ? 0 : 1

    readonly property bool isFocused: (content.item as Content)?.isInputFocused ?? false

    visible: offsetScale < 1
    anchors.left: parent.left
    anchors.bottom: parent.bottom
    anchors.bottomMargin: (-implicitHeight - 5) * offsetScale
    implicitWidth: 380
    implicitHeight: Math.min(520, parent.height * 0.65)
    opacity: 1 - offsetScale

    Behavior on offsetScale {
        Anim {}
    }

    Loader {
        id: content

        anchors.fill: parent

        active: root.shouldBeActive || root.visible

        sourceComponent: Content {
            screenState: root.screenState
        }
    }
}
