import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore

import "common/Utils.js" as Utils
import "common" as Common

Item {
    id: root

    readonly property int tooltipWaitDuration: 800
    readonly property int animationWidthDuration: 100
    readonly property int animationColorDuration: 150
    readonly property int animationOpacityDuration: 150

    property bool isCurrent: false
    property string name: ""
    property string id: ""
    property int number: 0
    property var windowNameList: buttonRect.windowNameList
    property Item container: null

    property bool isDragged: container?.draggedDesktopButton === this
    property bool ignoreMouseArea: container?.isDragging || false
    property bool isVisible: buttonRect.isVisible

    Layout.fillWidth: Common.LayoutProps.isVerticalOrientation
    Layout.fillHeight: !Common.LayoutProps.isVerticalOrientation

    Rectangle {
        id: buttonRect
        anchors.fill: parent

        property alias widthBehavior: widthBehavior
        property alias heightBehavior: heightBehavior

        property bool isEmpty: false
        property bool isUrgent: false
        property string activeWindowName: ""
        property var windowNameList: []

        property alias _label: label
        property alias _indicator: indicator

        clip: true
        color: "transparent"
        opacity: !config.AnimationsEnable ? 1 : 0

        Layout.fillWidth: Common.LayoutProps.isVerticalOrientation
        Layout.fillHeight: !Common.LayoutProps.isVerticalOrientation

        property bool isVisible: {
            if (config && config.DesktopButtonsShowOnlyForCurrentDesktop &&
                config.DesktopButtonsShowOnlyForOccupiedDesktops) {
                return root.isCurrent || !buttonRect.isEmpty;
            }
            if (config && config.DesktopButtonsShowOnlyForCurrentDesktop) {
                return root.isCurrent;
            }
            if (config && config.DesktopButtonsShowOnlyForOccupiedDesktops) {
                return !buttonRect.isEmpty;
            }
            return true;
        }

        onIsVisibleChanged: {
            container.updateNumberOfVisibleDesktopButtons()
            Qt.callLater(function() {
                if (isVisible) {
                    root.show();
                } else {
                    root.hide();
                }
            });
        }

        Behavior on opacity {
            enabled: config.AnimationsEnable
            animation: NumberAnimation {
                duration: animationOpacityDuration
            }
        }

        Behavior on implicitWidth {
            id: widthBehavior
            enabled: config.AnimationsEnable
            animation: NumberAnimation {
                duration: animationWidthDuration
                onRunningChanged: {
                    if (!running) {
                        Qt.callLater(function() {
                            if (container && typeof container.updateLargestDesktopButton === "function") {
                                container.updateLargestDesktopButton();
                            }
                        })
                    }
                }
            }
        }

        Behavior on implicitHeight {
            id: heightBehavior
            enabled: config.AnimationsEnable
            animation: NumberAnimation {
                duration: animationWidthDuration
            }
        }

        /* Indicator */
        Rectangle {
            id: indicator

            visible: config.DesktopIndicatorsStyle !== 5

            color: {
                if (isCurrent) {
                    return config.DesktopIndicatorsCustomColorForCurrentDesktop || PlasmaCore.Theme.buttonFocusColor;
                }
                if (buttonRect.isEmpty && config.DesktopIndicatorsCustomColorForIdleDesktops) {
                    return config.DesktopIndicatorsCustomColorForIdleDesktops;
                }
                if (!buttonRect.isEmpty && config.DesktopIndicatorsCustomColorForOccupiedIdleDesktops) {
                    return config.DesktopIndicatorsCustomColorForOccupiedIdleDesktops;
                }
                if (buttonRect.isUrgent && config.DesktopIndicatorsCustomColorForDesktopsNeedingAttention) {
                    return config.DesktopIndicatorsCustomColorForDesktopsNeedingAttention;
                }
                return PlasmaCore.Theme.textColor
            }

            Behavior on color {
                enabled: config.AnimationsEnable
                animation: ColorAnimation {
                    duration: animationColorDuration
                }
            }

            opacity: {
                if (isCurrent) {
                    return 1.0;
                }
                if ((!ignoreMouseArea && mouseArea.containsMouse) || isDragged) {
                    return config.DesktopIndicatorsStyle === 5 ? 1.0 : 0.75;
                }
                if (config.DesktopIndicatorsDoNotOverrideOpacityOfCustomColors) {
                    if ((isCurrent && config.DesktopIndicatorsCustomColorForCurrentDesktop) ||
                        (buttonRect.isEmpty && config.DesktopIndicatorsCustomColorForIdleDesktops) ||
                        (!buttonRect.isEmpty && config.DesktopIndicatorsCustomColorForOccupiedIdleDesktops) ||
                        (buttonRect.isUrgent && config.DesktopIndicatorsCustomColorForDesktopsNeedingAttention)) {
                        return 1.0;
                    }
                }
                if (!buttonRect.isEmpty && config.DesktopIndicatorsDistinctForOccupiedIdleDesktops) {
                    return config.DesktopIndicatorsStyle === 5 ? 1.0 : 0.5;
                }
                return config.DesktopIndicatorsStyle === 5 ? 0.5 : 0.25;
            }

            Behavior on opacity {
                enabled: config.AnimationsEnable
                animation: NumberAnimation {
                    duration: animationOpacityDuration
                }
            }

            width: {
                if (Common.LayoutProps.isVerticalOrientation) {
                    if (config.DesktopIndicatorsStyle === 1) {
                        return config.DesktopIndicatorsStyleLineThickness;
                    }
                    if (config.DesktopIndicatorsStyle === 4) {
                        return parent.width;
                    }
                    if (config.DesktopButtonsSetCommonSizeForAll &&
                        container.largestDesktopButton &&
                        container.largestDesktopButton !== parent &&
                        container.largestDesktopButton._label.implicitWidth > label.implicitWidth) {
                        return container.largestDesktopButton._indicator.width;
                    }
                    return label.implicitWidth + 2 * config.DesktopButtonsHorizontalMargin;
                }
                if (config.DesktopIndicatorsStyle === 1) {
                    return config.DesktopIndicatorsStyleLineThickness;
                }
                return parent.width + 0.5 - 2 * config.DesktopButtonsSpacing;
            }

            height: {
                if (config.DesktopIndicatorsStyle === 4) {
                    if (Common.LayoutProps.isVerticalOrientation) {
                        return parent.height + 0.5 - 2 * config.DesktopButtonsSpacing;
                    }
                    return parent.height;
                }
                if (config.DesktopIndicatorsStyle > 0) {
                    return label.implicitHeight + 2 * config.DesktopButtonsVerticalMargin;
                }
                return config.DesktopIndicatorsStyleLineThickness;
            }

            x: {
                if (Common.LayoutProps.isVerticalOrientation) {
                    if (config.DesktopIndicatorsStyle !== 1) {
                        return (parent.width - width) / 2;
                    }
                    return config.DesktopIndicatorsInvertPosition ?
                        parent.width - config.DesktopIndicatorsStyleLineThickness : 0;
                }
                if (config.DesktopIndicatorsStyle === 1 &&
                    config.DesktopIndicatorsInvertPosition) {
                    return parent.width - width - (config.DesktopButtonsSpacing || 0);
                }
                return config.DesktopButtonsSpacing || 0;
            }

            y: {
                if (config.DesktopIndicatorsStyle > 0) {
                    return (parent.height - height) / 2;
                }
                if (Common.LayoutProps.isTopLocation) {
                    return !config.DesktopIndicatorsInvertPosition ? parent.height - height : 0;
                }
                return !config.DesktopIndicatorsInvertPosition ? 0 : parent.height - height;
            }

            radius: {
                if (config.DesktopIndicatorsStyle === 2) {
                    return config.DesktopIndicatorsStyleBlockRadius;
                }
                if (config.DesktopIndicatorsStyle === 3) {
                    return 300;
                }
                return 0;
            }
        }

        /* Label */
        Text {
            id: label

            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter

            text: name

            color: config.DesktopIndicatorsStyle === 5 ?
                indicator.color :
                config.DesktopLabelsCustomColor || PlasmaCore.Theme.textColor

            Behavior on color {
                enabled: config.AnimationsEnable
                animation: ColorAnimation {
                    duration: animationColorDuration
                }
            }

            opacity: {
                if (config.DesktopIndicatorsStyle === 5) {
                    return indicator.opacity;
                }
                if (isCurrent) {
                    return 1.0;
                }
                if (config.DesktopLabelsDimForIdleDesktops) {
                    if ((!ignoreMouseArea && mouseArea.containsMouse) || isDragged) {
                        return 1.0;
                    }
                    return 0.75;
                }
                return 1.0;
            }

            Behavior on opacity {
                enabled: config.AnimationsEnable
                animation: NumberAnimation {
                    duration: animationOpacityDuration
                }
            }

            font.family: config.DesktopLabelsCustomFont || PlasmaCore.Theme.defaultFont.family
            font.pixelSize: config.DesktopLabelsCustomFontSize || PlasmaCore.Theme.defaultFont.pixelSize
            font.bold: isCurrent && config.DesktopLabelsBoldFontForCurrentDesktop
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton

            property var tooltipTimer

            function killTooltipTimer() {
                if (tooltipTimer) {
                    tooltipTimer.stop();
                    tooltipTimer = null;
                }
            }

            onEntered: {
                container.lastHoveredButton = parent.parent; // Use root instead of buttonRect

                if (!config.TooltipsEnable) {
                    return;
                }

                tooltipTimer = Utils.delay(tooltipWaitDuration, function() {
                    if (containsMouse && !isDragged) {
                        tooltip.show(parent.parent); // Use root instead of buttonRect
                    }
                }, root);
            }

            onExited: {
                if (config.TooltipsEnable) {
                    killTooltipTimer();
                    tooltip.visible = false;
                }
            }

            onClicked: {
                if (config.TooltipsEnable) {
                    killTooltipTimer();
                    tooltip.visible = false;
                }

                if (mouse.button === Qt.LeftButton) {
                    //backend.showDesktop(number);
                    // TODO: Delete when Backend.showDesktop is fixed
                    console.log("Show desktop requested: ", number);
                } else if (mouse.button === Qt.MiddleButton) {
                    if (!config.DynamicDesktopsEnable &&
                        config.MouseWheelRemoveDesktopOnClick) {
                        //backend.removeDesktop(number);
                        // TODO: Delete when Backend.showDesktop is fixed
                        console.log("Remove desktop requested: ", number);
                    }
                }
            }
        }

        onImplicitWidthChanged: {
            if (!config.AnimationsEnable) {
                Qt.callLater(function() {
                    if (container && typeof container.updateLargestDesktopButton === "function") {
                        container.updateLargestDesktopButton();
                    }
                })
            }
        }
    }

    function update(desktopInfo) {
        if (!desktopInfo) return;

        root.number = desktopInfo.number || 0;
        root.id = desktopInfo.id || "";
        root.name = desktopInfo.name || "";
        root.isCurrent = desktopInfo.isCurrent || desktopInfo.current || false;
        buttonRect.isEmpty = desktopInfo.isEmpty || !desktopInfo.occupied || false;
        buttonRect.isUrgent = desktopInfo.isUrgent || false;
        buttonRect.activeWindowName = desktopInfo.activeWindowName || "";
        buttonRect.windowNameList = desktopInfo.windowNameList || [];

        updateLabel();
    }

    function updateLabel() {
        buttonRect._label.text = Qt.binding(function() {
            var labelText = name;

            if (config.DesktopLabelsStyle === 1) {
                labelText = number + "";
            } else if (config.DesktopLabelsStyle === 2) {
                labelText = number + ": " + name;
            } else if (config.DesktopLabelsStyle === 3) {
                labelText = buttonRect.activeWindowName || name;
            } else if (config.DesktopLabelsStyle === 4) {
                if (config.DesktopLabelsStyleCustomFormat) {
                    var format = config.DesktopLabelsStyleCustomFormat.trim();
                    if (format.length > 0) {
                        labelText = format;
                        labelText = labelText.replace("$WX", !buttonRect.isEmpty ? buttonRect.activeWindowName : number);
                        labelText = labelText.replace("$WR", !buttonRect.isEmpty ? buttonRect.activeWindowName : Utils.arabicToRoman(number));
                        labelText = labelText.replace("$WN", !buttonRect.isEmpty ? buttonRect.activeWindowName : name);
                        labelText = labelText.replace("$X", number);
                        labelText = labelText.replace("$R", Utils.arabicToRoman(number));
                        labelText = labelText.replace("$N", name);
                        labelText = labelText.replace("$W", buttonRect.activeWindowName);
                    } else {
                        labelText = number + ": " + name;
                    }
                }
            }

            if (labelText.length > config.DesktopLabelsMaximumLength) {
                labelText = labelText.substr(0, config.DesktopLabelsMaximumLength - 1) + "…";
            }
            if (config.DesktopLabelsDisplayAsUppercased) {
                labelText = labelText.toUpperCase();
            }

            return labelText;
        });
    }

    function show() {
        if (!buttonRect.isVisible) {
            return;
        }

        buttonRect.visible = true;
        var self = buttonRect;

        if (container.numberOfVisibleDesktopButtons === 1) {
            buttonRect.widthBehavior.enabled = buttonRect.heightBehavior.enabled = false;
        }

        implicitWidth = Qt.binding(function() {
            if (Common.LayoutProps.isVerticalOrientation) {
                return root.width;
            }

            var newImplicitWidth = buttonRect._label.implicitWidth +
                2 * config.DesktopButtonsHorizontalMargin +
                2 * config.DesktopButtonsSpacing;

            if (config.DesktopButtonsSetCommonSizeForAll &&
                container.largestDesktopButton &&
                container.largestDesktopButton !== root &&
                container.largestDesktopButton.buttonRect.implicitWidth > newImplicitWidth) {
                return container.largestDesktopButton.buttonRect.implicitWidth;
            }

            return newImplicitWidth;
        });

        implicitHeight = Qt.binding(function() {
            if (!Common.LayoutProps.isVerticalOrientation) {
                return buttonRect.height;
            }
            return buttonRect._label.implicitHeight +
                2 * config.DesktopButtonsVerticalMargin +
                2 * config.DesktopButtonsSpacing;
        });

        if (config.AnimationsEnable) {
            Qt.callLater(function() {
                buttonRect.opacity = 1;
            })
        } else {
            buttonRect.opacity = 1;
        }

        buttonRect.widthBehavior.enabled = buttonRect.heightBehavior.enabled = Qt.binding(function() {
            return config.AnimationsEnable;
        });
    }

    function hide(callback, force) {
        if (!force && buttonRect.isVisible) {
            return;
        }

        buttonRect.opacity = 0;

        if (container.numberOfVisibleDesktopButtons === 1) {
            buttonRect.widthBehavior.enabled = buttonRect.heightBehavior.enabled = false;
        }

        var resetDimensions = function() {
            buttonRect.implicitWidth = Common.LayoutProps.isVerticalOrientation ? buttonRect.width : 0;
            buttonRect.implicitHeight = Common.LayoutProps.isVerticalOrientation ? 0 : buttonRect.height;
        }

        var self = buttonRect;
        var postHideCallback = callback ? callback : function() {
            self.visible = false;
            buttonRect.widthBehavior.enabled = buttonRect.heightBehavior.enabled = Qt.binding(function() {
                return config.AnimationsEnable;
            });
        };

        if (config.AnimationsEnable && container.numberOfVisibleDesktopButtons > 1) {
            Qt.callLater(function() {
                resetDimensions();
                Utils.delay(animationWidthDuration, postHideCallback, root);
            });

        } else {
            resetDimensions();
            postHideCallback();
        }
    }
}
