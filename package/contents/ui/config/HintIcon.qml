import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami 2.20 as Kirigami
import org.kde.plasma.core as PlasmaCore
import Qt5Compat.GraphicalEffects

import "../common" as UICommon
import "../"

Item {
    id: root
    implicitWidth: Kirigami.Units.iconSizes.smallMedium + Kirigami.Units.smallSpacing
    implicitHeight: Kirigami.Units.iconSizes.smallMedium

    property string tooltipText
    property bool tooltipInitialized: false
    property bool showOnRight: true
    property bool showBelow: true

    Kirigami.Icon {
        id: icon
        source: "help-contextual"
        width: Kirigami.Units.iconSizes.smallMedium
        height: Kirigami.Units.iconSizes.smallMedium
        Layout.maximumWidth: width
        Layout.maximumHeight: height

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true

            onContainsMouseChanged: {
                if (containsMouse && !tooltipInitialized) {
                    tooltipInitialized = true;

                    let rootWindow = icon;
                    while (rootWindow.parent) {
                        rootWindow = rootWindow.parent;
                    }

                    let iconPos = icon.mapToItem(rootWindow, 0, 0);
                    let availableRight = rootWindow.width - (iconPos.x + icon.width);
                    let availableDown = rootWindow.height - (iconPos.y + icon.height);
                    let tooltipWidth = tooltip.contentItem.implicitWidth + tooltip.leftPadding + tooltip.rightPadding;
                    let tooltipHeight = tooltip.contentItem.implicitHeight + tooltip.topPadding + tooltip.bottomPadding;

                    availableRight -= 15; //Add some padding just so we don't get too close to the edge
                    availableDown -= 15;  //Add some padding just so we don't get too close to the edge

                    if (availableRight >= tooltipWidth) {
                        tooltip.x = icon.width;
                        showOnRight = true;
                        backgroundRect.topLeftRadius = 0;
                        backgroundRect.bottomLeftRadius = 0;
                        backgroundRect.topRightRadius = 6;
                        backgroundRect.bottomRightRadius = 6;
                    } else {
                        showOnRight = false;
                        backgroundRect.topLeftRadius = 6;
                        backgroundRect.bottomLeftRadius = 6;
                        backgroundRect.topRightRadius = 0;
                        backgroundRect.bottomRightRadius = 0;
                    }

                    if (availableDown >= tooltipHeight) {
                        tooltip.y = 0;
                        showBelow = true;
                    } else {
                        showBelow = false;
                    }

                } else if (!containsMouse) {
                    tooltipInitialized = false;
                }
            }
        }

        ToolTip {
            id: tooltip
            visible: mouseArea.containsMouse
            font: Kirigami.Theme.defaultFont
            padding: Kirigami.Units.smallSpacing

            onWidthChanged: {
                if (!showOnRight) {
                    x = -width;
                }
            }

            onHeightChanged: {
                if (!showBelow) {
                    y = (-height) + icon.height;
                }
            }

            width: contentItem.implicitWidth + leftPadding + rightPadding
            height: contentItem.implicitHeight + topPadding + bottomPadding

            enter: Transition {
                ParallelAnimation {
                    NumberAnimation {
                        target: tooltip
                        properties: "width"
                        from: 0
                        to: tooltip.implicitWidth
                        duration: 150
                        easing.type: Easing.OutQuad
                    }

                    NumberAnimation {
                        target: tooltip
                        properties: "height"
                        from: 0
                        to: tooltip.implicitHeight
                        duration: 150
                        easing.type: Easing.OutQuad
                    }
                }
            }

            exit: Transition {
                ParallelAnimation {
                    NumberAnimation {
                        target: tooltip
                        properties: "width"
                        from: tooltip.implicitWidth
                        to: 0
                        duration: 150
                        easing.type: Easing.OutQuad
                    }

                    NumberAnimation {
                        target: tooltip
                        properties: "height"
                        from: tooltip.implicitHeight
                        to: 0
                        duration: 150
                        easing.type: Easing.OutQuad
                    }
                }
            }

            background: Rectangle {
                id: backgroundRect
                z: 50
                anchors.fill: parent
                color: PlasmaCore.Theme.viewBackgroundColor
                border.width: 1
                border.color: PlasmaCore.Theme.disabledTextColor
            }

            contentItem: Text {
                z: 99
                anchors.centerIn: parent
                text: root.tooltipText
                color: Kirigami.Theme.textColor
                wrapMode: Text.NoWrap
                clip: true
            }
        }
    }
}
