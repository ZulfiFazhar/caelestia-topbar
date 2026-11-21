import QtQuick
import Caelestia.Config
import qs.components
import qs.components.effects
import qs.services
import qs.utils

Item {
    id: root

    readonly property real scaleFactor: Tokens.sizes.bar.innerWidth / 40

    implicitWidth: Math.round(Tokens.font.body.large.pointSize * 1.2 * scaleFactor)
    implicitHeight: Math.round(Tokens.font.body.large.pointSize * 1.2 * scaleFactor)

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            const screenState = ShellState.forActive();
            screenState.launcher = !screenState.launcher;
        }
    }

    Loader {
        asynchronous: true
        anchors.centerIn: parent
        sourceComponent: SysInfo.isDefaultLogo ? caelestiaLogo : distroIcon
    }

    Component {
        id: caelestiaLogo

        Logo {
            implicitWidth: Math.round(Tokens.font.body.large.pointSize * 1.6 * root.scaleFactor)
            implicitHeight: Math.round(Tokens.font.body.large.pointSize * 1.6 * root.scaleFactor)
        }
    }

    Component {
        id: distroIcon

        ColouredIcon {
            source: SysInfo.osLogo
            implicitSize: Math.round(Tokens.font.body.large.pointSize * 1.2 * root.scaleFactor)
            colour: Colours.palette.m3tertiary
        }
    }
}
