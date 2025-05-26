import QtQuick
import QtQuick.Controls
import org.kde.plasma.core as PlasmaCore
import "../common" as Common
import "../common/IndicatorStyles.js" as IndicatorStyles

Rectangle {
    property QtObject config: plasmoid.configuration

    readonly property int animationColorDuration: 300
    readonly property int animationOpacityDuration: 300

    property int indicatorStyle: config.DesktopIndicatorsStyle
    
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
                return config.DesktopIndicatorsStyleLineThickness;
            }
            if (indicatorStyle === IndicatorStyles.FullSize) {
                return parent.width;
            }

            return parent.width + 0.5 - 2 * config.DesktopButtonsHorizontalMargin;
        }
        if (indicatorStyle === IndicatorStyles.SideLine) {
            return config.DesktopIndicatorsStyleLineThickness;
        }

        return parent.width + 0.5 - 2 * config.DesktopButtonsSpacing;
    }

    height: {
        if (indicatorStyle === IndicatorStyles.FullSize) {
            if (Common.LayoutProps.isVerticalOrientation) {
                return parent.height + 0.5 - 2 * config.DesktopButtonsSpacing;
            }
            return parent.height;
        }
        if (indicatorStyle > IndicatorStyles.EdgeLine) {
            return label.implicitHeight + 2 * config.DesktopButtonsVerticalMargin;
        }
        return config.DesktopIndicatorsStyleLineThickness;
    }

    x: {
        if (Common.LayoutProps.isVerticalOrientation) {
            if (indicatorStyle !== IndicatorStyles.SideLine) {
                return (parent.width - width) / 2;
            }
            return config.DesktopIndicatorsInvertPosition ?
                parent.width - config.DesktopIndicatorsStyleLineThickness : 0;
        }
        if (indicatorStyle === IndicatorStyles.SideLine &&
            config.DesktopIndicatorsInvertPosition) {
            return parent.width - width - (config.DesktopButtonsSpacing || 0);
        }
        return config.DesktopButtonsSpacing || 0;
    }

    y: {
        if (indicatorStyle > IndicatorStyles.EdgeLine) {
            return (parent.height - height) / 2;
        }
        if (Common.LayoutProps.isTopLocation) {
            return !config.DesktopIndicatorsInvertPosition ? parent.height - height : 0;
        }
        return !config.DesktopIndicatorsInvertPosition ? 0 : parent.height - height;
    }

    radius: {
        if (indicatorStyle === IndicatorStyles.Block) {
            return config.DesktopIndicatorsStyleBlockRadius;
        }
        if (indicatorStyle === IndicatorStyles.Rounded) {
            return 300;
        }
        return 0;
    }
}
