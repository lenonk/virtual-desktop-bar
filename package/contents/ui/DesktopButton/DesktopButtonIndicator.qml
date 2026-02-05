import QtQuick
import QtQuick.Controls
import org.kde.plasma.core as PlasmaCore
import "../common" as Common
import "../common/IndicatorStyles.js" as IndicatorStyles

Rectangle {
    property QtObject config: plasmoid.configuration

    readonly property int animationColorDuration: 300
    readonly property int animationOpacityDuration: 300
    readonly property real spacing: config.ButtonSpacing || 0
    readonly property bool fillButton: indicatorStyle === IndicatorStyles.Block ||
        indicatorStyle === IndicatorStyles.Rounded ||
        indicatorStyle === IndicatorStyles.FullSize


    property int indicatorStyle: config.IndicatorStyle

    visible: indicatorStyle !== IndicatorStyles.UseLabels

    Behavior on color {
        enabled: config.AnimationsEnable
        animation: ColorAnimation { duration: animationColorDuration }
    }

    Behavior on opacity {
        enabled: config.AnimationsEnable
        animation: NumberAnimation { duration: animationOpacityDuration }
    }

    width: {
        if (Common.LayoutProps.isVerticalOrientation) {
            if (indicatorStyle === IndicatorStyles.SideLine) {
                return config.IndicatorLineThickness;
            }
            // if (indicatorStyle === IndicatorStyles.FullSize) {
            //     return parent.width;
            // }
            if (fillButton) {
                return parent.width + 0.5 - 2 * spacing;
            }
            if (indicatorStyle > IndicatorStyles.EdgeLine) {
                return label.implicitWidth + 2 * config.ButtonMarginHorizontal;
            }
            return parent.width + 0.5 - 2 * spacing;
        }

        if (indicatorStyle === IndicatorStyles.SideLine) {
            return config.IndicatorLineThickness;
        }

        // if (indicatorStyle > IndicatorStyles.EdgeLine) {
        //     return label.implicitWidth + 2 * config.ButtonMarginHorizontal;
        // }
        if (fillButton) {
            return parent.width + 0.5 - 2 * spacing;
        }

        return parent.width + 0.5 - 2 * spacing;
    }

    height: {
        if (indicatorStyle === IndicatorStyles.FullSize) {
            if (Common.LayoutProps.isVerticalOrientation) {
                return parent.height + 0.5 - 2 * config.ButtonSpacing;
            }
            return parent.height;
        }
        if (indicatorStyle > IndicatorStyles.EdgeLine) {
            return label.implicitHeight + 2 * config.ButtonMarginVertical;
        }
        return config.IndicatorLineThickness;
    }

    x: {
        if (Common.LayoutProps.isVerticalOrientation) {
            if (indicatorStyle !== IndicatorStyles.SideLine) {
                // return (parent.width - width) / 2;
                return fillButton ? spacing : (parent.width - width) / 2;
            }
            return config.IndicatorInvert ?
                parent.width - config.IndicatorLineThickness : 0;
        }

        if (indicatorStyle === IndicatorStyles.SideLine && config.IndicatorInvert) {
            return parent.width - width - spacing;
        }
        return spacing;
    }

    y: {
        if (indicatorStyle > IndicatorStyles.EdgeLine) {
            return (parent.height - height) / 2;
        }
        if (Common.LayoutProps.isTopLocation) {
            return !config.IndicatorInvert ? parent.height - height : 0;
        }
        return !config.IndicatorInvert ? 0 : parent.height - height;
    }

    radius: {
        if (indicatorStyle === IndicatorStyles.Block) {
            return config.IndicatorBlockRadius;
        }
        if (indicatorStyle === IndicatorStyles.Rounded) {
            return 300;
        }
        return 0;
    }
}
