pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services

StyledRect {
    id: root

    readonly property real scaleFactor: Tokens.sizes.bar.innerWidth / 40
    readonly property color colour: Colours.palette.m3tertiary
    readonly property int padding: Config.bar.clock.background ? Tokens.padding.medium : Tokens.padding.extraSmall
    readonly property var font: Tokens.font.body.builders.small.scale(1.1 * scaleFactor)

    implicitHeight: Tokens.sizes.bar.innerWidth
    implicitWidth: layout.implicitWidth + root.padding * 2

    color: Qt.alpha(Colours.tPalette.m3surfaceContainer, Config.bar.clock.background ? Colours.tPalette.m3surfaceContainer.a : 0)
    radius: Tokens.rounding.full

    RowLayout {
        id: layout

        anchors.centerIn: parent
        spacing: Tokens.spacing.small

        Loader {
            Layout.alignment: Qt.AlignVCenter
            asynchronous: true
            active: Config.bar.clock.showIcon
            visible: active

            sourceComponent: MaterialIcon {
                text: "calendar_month"
                color: root.colour
                fontStyle: Tokens.font.icon.builders.small.scale(root.scaleFactor).build()
            }
        }

        Loader {
            Layout.alignment: Qt.AlignVCenter
            asynchronous: true
            active: Config.bar.clock.showDate
            visible: active

            sourceComponent: RowLayout {
                spacing: Tokens.spacing.extraSmall

                StyledText {
                    Layout.alignment: Qt.AlignVCenter
                    text: Time.format("ddd")
                    font: Tokens.font.body.builders.small.scale(0.9 * root.scaleFactor).build()
                    color: root.colour
                }

                StyledText {
                    Layout.alignment: Qt.AlignVCenter
                    text: Time.format("d")
                    font: root.font.scale(1.05).build()
                    color: root.colour
                }

                StyledRect {
                    Layout.alignment: Qt.AlignVCenter
                    implicitWidth: 1
                    implicitHeight: Math.round(14 * root.scaleFactor)
                    color: Colours.palette.m3outlineVariant
                }
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignVCenter
            spacing: 0

            StyledText {
                Layout.alignment: Qt.AlignVCenter
                text: Time.hourStr + ":" + Time.minuteStr
                font: root.font.build()
                color: root.colour
            }

            Loader {
                Layout.alignment: Qt.AlignVCenter
                asynchronous: true
                active: Config.bar.clock.showSeconds
                visible: active

                sourceComponent: StyledText {
                    text: ":" + Time.format("ss")
                    font: root.font.build()
                    color: root.colour
                }
            }

            Loader {
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: 2
                asynchronous: true
                active: Units.twelveHourClock
                visible: active

                sourceComponent: StyledText {
                    text: Time.amPmStr.toLowerCase()
                    font: Tokens.font.body.builders.small.scale(0.85 * root.scaleFactor).build()
                    color: root.colour
                }
            }
        }
    }
}
