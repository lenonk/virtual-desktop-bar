import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../common" as Common

Rectangle {
    id: buttonDragPlaceholder

    property int verticalMargins: 5
    property int horizontalPadding: 5 + (Common.LayoutProps.isVerticalOrientation ? 0 : config.ButtonSpacing)
    property int verticalPadding: 5 + (Common.LayoutProps.isVerticalOrientation ? config.ButtonSpacing : 0)

    Layout.fillHeight: !Common.LayoutProps.isVerticalOrientation
    Layout.fillWidth: Common.LayoutProps.isVerticalOrientation
    Layout.topMargin: verticalMargins
    Layout.bottomMargin: verticalMargins

    SystemPalette { id: systemPalette }

    SequentialAnimation {
        id: dragVisualPulseAnimation

        running: true
        loops: Animation.Infinite

        onStopped: {
            buttonDragPlaceholder.opacity = 0.9;
        }

        NumberAnimation {
            target: buttonDragPlaceholder
            property: "opacity"
            from: 0.9
            to: 0.3
            duration: 1000
            easing.type: Easing.InOutQuad
        }
        NumberAnimation {
            target: buttonDragPlaceholder
            property: "opacity"
            from: 0.3
            to: 0.9
            duration: 1000
            easing.type: Easing.InOutQuad
        }
    }

    visible: true
    color: "transparent"

    radius: 4
    border.width: 1
    border.color: systemPalette.highlight
}
