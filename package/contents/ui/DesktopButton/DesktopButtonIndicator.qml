import QtQuick
import QtQuick.Controls
import org.kde.plasma.core as PlasmaCore

import "../common" as Common
import "../common/IndicatorStyles.js" as IndicatorStyles
import "../common/IndicatorPolicy.js" as IndicatorPolicy
import "../common/IndicatorGeometry.js" as IndicatorGeometry

Rectangle {
    property QtObject config: plasmoid.configuration

    readonly property int animationColorDuration: 300
    readonly property int animationOpacityDuration: 300

    readonly property real spacing: config.ButtonSpacing || 0
    property int indicatorStyle: config.IndicatorStyle

    readonly property bool fillButton: IndicatorPolicy.usesFill(indicatorStyle)
    readonly property bool usesLabelMetrics: IndicatorPolicy.usesLabelMetrics(indicatorStyle)

    // TODO: Make this configurable?
    readonly property int indicatorLabelGap: 10
    readonly property int sideLineLabelReserve: IndicatorPolicy.sideLineLabelReserve(
        indicatorStyle, config, indicatorLabelGap
    )

    readonly property var geom: IndicatorGeometry.computeGeometry({
        style: indicatorStyle,
        config: config,

        isVertical: Common.LayoutProps.isVerticalOrientation,
        isTopLocation: Common.LayoutProps.isTopLocation,

        parentWidth: parent.width,
        parentHeight: parent.height,

        labelImplicitWidth: label.implicitWidth,
        labelImplicitHeight: label.implicitHeight,

        spacing: spacing,
        fillButton: fillButton,
        usesLabelMetrics: usesLabelMetrics
    })

    visible: IndicatorPolicy.isVisible(indicatorStyle)

    Behavior on color {
        enabled: config.AnimationsEnable
        animation: ColorAnimation {
            duration: animationColorDuration
        }
    }

    Behavior on opacity {
        enabled: config.AnimationsEnable
        animation: NumberAnimation {
            duration: animationOpacityDuration
        }
    }

    width: geom.w
    height: geom.h
    x: geom.x
    y: geom.y
    radius: geom.r
}