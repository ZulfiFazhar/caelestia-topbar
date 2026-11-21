pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services
import qs.utils

Item {
    id: root

    required property var bar
    required property Brightness.Monitor monitor
    property color colour: Colours.palette.m3primary

    readonly property string windowTitle: {
        const title = Hypr.activeToplevel?.title;
        if (!title)
            return Tr.trCtx("Desktop", "shown when no window is focused");
        if (Config.bar.activeWindow.compact) {
            // " - " (standard hyphen), " — " (em dash), " – " (en dash)
            const parts = title.split(/\s+[\-\u2013\u2014]\s+/);
            if (parts.length > 1)
                return parts[parts.length - 1].trim();
        }
        return title;
    }

    readonly property int maxWidth: {
        const otherModules = bar.children.filter(c => c.entryId && c.item !== this && c.entryId !== "spacer");
        const otherWidth = otherModules.reduce((acc, curr) => acc + (curr.item.nonAnimWidth ?? curr.width), 0);
        return Math.max(100, Math.min(350, bar.width - otherWidth - bar.spacing * (bar.children.length - 1) - bar.hPadding * 2));
    }
    property Title current: text1

    clip: true
    implicitHeight: Tokens.sizes.bar.innerWidth
    implicitWidth: icon.implicitWidth + current.implicitWidth + Tokens.spacing.small

    Loader {
        asynchronous: true
        anchors.fill: parent
        active: !Config.bar.activeWindow.showOnHover

        sourceComponent: MouseArea {
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onPositionChanged: {
                const popouts = root.bar.popouts;
                if (popouts.hasCurrent && popouts.currentName !== "activewindow")
                    popouts.hasCurrent = false;
            }
            onClicked: {
                const popouts = root.bar.popouts;
                if (popouts.hasCurrent) {
                    popouts.hasCurrent = false;
                } else {
                    popouts.currentName = "activewindow";
                    popouts.currentCenter = root.mapToItem(root.bar, root.implicitWidth / 2, 0).x;
                    popouts.hasCurrent = true;
                }
            }
        }
    }

    RowLayout {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        spacing: Tokens.spacing.small

        MaterialIcon {
            id: icon

            Layout.alignment: Qt.AlignVCenter
            animate: true
            text: Icons.getAppCategoryIcon(Hypr.activeToplevel?.lastIpcObject.class, "desktop_windows")
            color: root.colour
            fontStyle: Tokens.font.icon.builders.small.scale(Tokens.sizes.bar.innerWidth / 40).build()
        }

        Item {
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: root.current.implicitWidth
            implicitHeight: root.current.implicitHeight

            Title {
                id: text1
            }

            Title {
                id: text2
            }
        }
    }

    TextMetrics {
        id: metrics

        text: root.windowTitle
        font: root.Tokens.font.body.builders.small.scale(Tokens.sizes.bar.innerWidth / 40).letterSpacing(1.4).build()
        elide: Qt.ElideRight
        elideWidth: Math.max(50, root.maxWidth - icon.width - 8)

        onTextChanged: {
            const next = root.current === text1 ? text2 : text1;
            next.text = elidedText;
            root.current = next;
        }
        onElideWidthChanged: root.current.text = elidedText
    }

    Behavior on implicitWidth {
        Anim {}
    }

    component Title: StyledText {
        id: text

        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left

        font: metrics.font
        color: root.colour
        opacity: root.current === this ? 1 : 0
        horizontalAlignment: Text.AlignLeft

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }
}
