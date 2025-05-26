import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

import "../common" as Common
import "../common/IndicatorStyles.js" as IndicatorStyles
import "../common/Utils.js" as Utils

Rectangle {
    id: buttonRect

    property QtObject config: plasmoid.configuration

    readonly property int tooltipDelay: 650
    readonly property int animationSizeDuration: 100
    readonly property int animationVisibilityDuration: 350

    property bool ignoreMouseArea: false
    property bool isCurrent: false
    // TODO: Set up a signal to set isDragged to to and ignoreMouseArea to true
    property bool isDragged: false
    property bool isEmpty: true
    property bool isFirst: false
    property bool isLast: false
    property bool isUrgent: false
    property string name: ""
    property int number: 0
    property string uuid: ""
    property string activeWindowName: ""
    property alias mouseArea: _mouseArea

    property int verticalMargins: 5
    property int horizontalPadding: 5 + (Common.LayoutProps.isVerticalOrientation ? 0 : config.DesktopButtonsSpacing)
    property int verticalPadding: 5 + (Common.LayoutProps.isVerticalOrientation ? config.DesktopButtonsSpacing : 0)

    Layout.bottomMargin: verticalMargins
    Layout.fillHeight: !Common.LayoutProps.isVerticalOrientation
    Layout.fillWidth: Common.LayoutProps.isVerticalOrientation
    Layout.topMargin: verticalMargins

    implicitHeight: label.implicitHeight + 2 * verticalPadding
    implicitWidth: label.implicitWidth + 2 * horizontalPadding

    opacity: applyOpacityRules()
    color: applyColorRules()

    // States for animation
    state: "creating"
    visible: true

    SystemPalette { id: systemPalette }

    Timer {
        id: taskUpateTimer
        interval: 500
        repeat: true
        running: true

        onTriggered: {
            updateTaskInfo();
        }
    }

    Behavior on Layout.preferredHeight {
        enabled: config.AnimationsEnable

        NumberAnimation {
            duration: animationSizeDuration
        }
    }
    Behavior on Layout.preferredWidth {
        enabled: config.AnimationsEnable

        NumberAnimation {
            duration: animationSizeDuration
        }
    }

    states: [
        State {
            name: "creating"

            PropertyChanges {
                opacity: 0.0
                target: buttonRect
            }
        },
        State {
            name: "visible"

            PropertyChanges {
                opacity: 1.0
                target: buttonRect
            }
        },
        State {
            name: "removing"

            PropertyChanges {
                opacity: 0.0
                target: buttonRect
            }
        }
    ]

    transitions: [
        Transition {
            enabled: config.AnimationsEnable
            from: "creating"
            to: "visible"

            NumberAnimation {
                duration: animationVisibilityDuration
                easing.type: Easing.OutQuad
                property: "opacity"
                target: buttonRect
            }
        },
        Transition {
            enabled: config.AnimationsEnable
            from: "visible"
            to: "removing"

            onRunningChanged: {
                if (!running && buttonRect.opacity === 0.0) {
                    buttonRemoveAnimationCompleted(buttonRect.uuid);
                }
            }

            NumberAnimation {
                duration: animationVisibilityDuration
                easing.type: Easing.InQuad
                property: "opacity"
                target: buttonRect
            }
        }
    ]

    Component.onCompleted: {
        state = "creating";
        createTimer.start();
        updateTaskInfo();
    }

    onImplicitWidthChanged: {
        Qt.callLater(onButtonImplicitWidthChanged);
    }

    onIsCurrentChanged: {
        Qt.callLater(applyOpacityRules);
        Qt.callLater(applyColorRules);
    }

    Timer {
        id: createTimer

        interval: 10
        repeat: false

        onTriggered: buttonRect.state = "visible"
    }

    DesktopButtonIndicator {
        id: indicator
    }

    DesktopButtonLabel {
        id: label

        text: getButtonLabel()
    }

    MouseArea {
        id: _mouseArea

        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        anchors.fill: parent
        hoverEnabled: true

        onClicked: function(mouse) {
            Qt.callLater(function() {
                hoverTimer.stop();
                hideDesktopButtonTooltip(true);
            });

            if (mouse.button === Qt.LeftButton) {
                desktopButtonClicked(buttonRect.number);
                mouse.accepted = true;
            } else if (mouse.button === Qt.MiddleButton) {
                if (config.MouseWheelRemoveDesktopOnClick) {
                    buttonMiddleClick(buttonRect);
                    mouse.accepted = true;
                }
            }
        }

        onContainsMouseChanged: {
            applyOpacityRules();
            applyColorRules();
            desktopButtonHovered(buttonRect);
        }

        onEntered: {
            hoverTimer.start();
        }

        onExited: {
            hoverTimer.stop();
            Utils.delay(100, function () {
                    hideDesktopButtonTooltip(false);
            }, _mouseArea);
        }

        Timer {
            id: hoverTimer

            interval: tooltipDelay
            repeat: false

            onTriggered: {
                showDesktopButtonTooltip(buttonRect);
            }
        }
    }

    function applyColorRules() {
        let indicatorColor = Kirigami.Theme.textColor;

        if (isCurrent) {
            //indicatorColor = config.DesktopIndicatorsCustomColorForCurrentDesktop || PlasmaCore.Theme.highlightColor
            indicatorColor = config.DesktopIndicatorsCustomColorForCurrentDesktop || systemPalette.highlight
        }
        if (isEmpty && config.DesktopIndicatorsCustomColorForIdleDesktops) {
            indicatorColor = config.DesktopIndicatorsCustomColorForIdleDesktops;
        }
        if (!isEmpty && config.DesktopIndicatorsCustomColorForOccupiedIdleDesktops) {
            indicatorColor = config.DesktopIndicatorsCustomColorForOccupiedIdleDesktops;
        }
        if (isUrgent) {
            indicatorColor = "#e6520c"
            if (config.DesktopIndicatorsCustomColorForDesktopsNeedingAttention) {
                indicatorColor = config.DesktopIndicatorsCustomColorForDesktopsNeedingAttention;
            }
        }

        let labelColor = config.DesktopIndicatorsStyle === IndicatorStyles.UseLabels ? indicatorColor :
            (config.DesktopLabelsCustomColor || Kirigami.Theme.textColor);

        indicator.color = indicatorColor;
        label.color = labelColor;

        return "transparent";
    }
    function applyOpacityRules() {
        let indicatorStyle = config.DesktopIndicatorsStyle;

        // Determine indicator opacity
        let indOpacity = 1;
        let lblOpacity = 1;
        if (isCurrent) {
            indOpacity = 1.0;
            lblOpacity = 1.0;
        } else if ((!ignoreMouseArea && _mouseArea.containsMouse) || isDragged) {
            indOpacity = (indicatorStyle === 5) ? 1.0 : 0.75;
        } else if (config.DesktopIndicatorsDoNotOverrideOpacityOfCustomColors) {
            const hasCustomColor = (isCurrent && config.DesktopIndicatorsCustomColorForCurrentDesktop) ||
                (isEmpty && config.DesktopIndicatorsCustomColorForIdleDesktops) ||
                (!isEmpty && config.DesktopIndicatorsCustomColorForOccupiedIdleDesktops) ||
                (isUrgent && config.DesktopIndicatorsCustomColorForDesktopsNeedingAttention);
            if (hasCustomColor) {
                indOpacity = 1.0;
            } else if (!isEmpty && config.DesktopIndicatorsDistinctForOccupiedIdleDesktops) {
                indOpacity = (indicatorStyle === 5) ? 1.0 : 0.5;
            } else {
                indOpacity = (indicatorStyle === 5) ? 0.5 : 0.25;
            }
        } else if (!isEmpty && config.DesktopIndicatorsDistinctForOccupiedIdleDesktops) {
            indOpacity = (indicatorStyle === 5) ? 1.0 : 0.5;
        } else {
            indOpacity = (indicatorStyle === 5) ? 0.5 : 0.25;
        }

        // Determine label opacity
        if (indicatorStyle === IndicatorStyles.UseLabels) {
            lblOpacity = indOpacity; // Use same opacity as indicator when using label style
        } else if ((!ignoreMouseArea && _mouseArea.containsMouse) || isDragged) {
            lblOpacity = 1.0;
        } else if (!isCurrent && config.DesktopLabelsDimForIdleDesktops) {
            lblOpacity = 0.75;
        } else {
            lblOpacity = 1.0;
        }

        // Apply opacities
        indicator.opacity = indOpacity;
        label.opacity = lblOpacity;

        // For the button itself, always return 1.0
        return 1.0;
    }
    function startRemoveAnimation() {
        state = "removing";
        return;
    }

    function getButtonLabel() {
        let labelText = name;

        if (config.DesktopLabelsStyle === IndicatorStyles.SideLine) {
            labelText = number + "";
        } else if (config.DesktopLabelsStyle === IndicatorStyles.Block) {
            labelText = number + ": " + name;
        } else if (config.DesktopLabelsStyle === IndicatorStyles.Rounded) {
            labelText = activeWindowName || name;
        } else if (config.DesktopLabelsStyle === IndicatorStyles.FullSize) {
            if (config.DesktopLabelsStyleCustomFormat) {
                var format = config.DesktopLabelsStyleCustomFormat.trim();
                if (format.length > 0) {
                    labelText = format;
                    labelText = labelText.replace("$WX", !isEmpty ? activeWindowName : number);
                    labelText = labelText.replace("$WR", !isEmpty ? activeWindowName : Utils.arabicToRoman(number));
                    labelText = labelText.replace("$WN", !isEmpty ? activeWindowName : name);
                    labelText = labelText.replace("$X", number);
                    labelText = labelText.replace("$R", Utils.arabicToRoman(number));
                    labelText = labelText.replace("$N", name);
                    labelText = labelText.replace("$W", activeWindowName);
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
    }

    function updateTaskInfo() {
        const activityId = backend.getCurrentActivityId();
        activeWindowName = Common.TaskManager.getActiveWindowName(uuid, activityId);
        isEmpty = !Common.TaskManager.hasWindows(uuid, activityId);
        isUrgent = Common.TaskManager.desktopNeedsAttention(uuid, activityId);

        // Update appearance if properties changed
        Qt.callLater(applyOpacityRules);
        Qt.callLater(applyColorRules);

        // Force label update
        label.text = getButtonLabel();
    }
}
