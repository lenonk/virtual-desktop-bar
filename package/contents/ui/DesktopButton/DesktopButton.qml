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

    property var buttonTooltip: null

    property bool ignoreMouseArea: false
    property bool isCurrent: false
    property bool isDragged: false
    property bool isEmpty: true
    property bool isFirst: false
    property bool isLast: false
    property bool isUrgent: false
    property string name: ""
    property int number: 0
    property int modelIdx: -1
    property string uuid: ""
    property string activeWindowName: ""
    property Item buttonGrid: null

    property alias mouseArea: _mouseArea

    property int verticalMargins: 5
    property int horizontalPadding: 5 + (Common.LayoutProps.isVerticalOrientation ? 0 : config.ButtonSpacing)
    property int verticalPadding: 5 + (Common.LayoutProps.isVerticalOrientation ? config.ButtonSpacing : 0)

    Layout.fillHeight: !Common.LayoutProps.isVerticalOrientation
    Layout.fillWidth: Common.LayoutProps.isVerticalOrientation
    Layout.topMargin: verticalMargins
    Layout.bottomMargin: verticalMargins

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

    Component {
        id: tooltipComponent
        DesktopButtonTooltip {
            buttonGrid: buttonRect.buttonGrid
        }
    }

    Component.onCompleted: {
        state = "creating";
        createTimer.start();
        updateTaskInfo();
        buttonTooltip = tooltipComponent.createObject(this, {"sourceButton": this});
    }

    onImplicitWidthChanged: {
        if (!_mouseArea.isDragging) {
            Qt.callLater(onButtonImplicitWidthChanged);
        }
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

    Rectangle {
        id: dragBorderHighlight

        anchors.fill: parent
        visible: false  // Disabled: border when dragging WindowListItem
        color: "transparent"

        border.width: 1
        border.color: systemPalette.highlight
    }

    Rectangle {
        id: dragHighlight

        property bool dragIsHovered: false

        anchors.fill: parent
        visible: dragIsHovered

        color: Qt.rgba(systemPalette.highlight.r, systemPalette.highlight.g, systemPalette.highlight.b, 0.2)

        border.width: 1
        border.color: systemPalette.highlight

        SequentialAnimation {
            id: buttonPulseAnimation

            running: parent.visible
            loops: Animation.Infinite

            NumberAnimation {
                target: dragHighlight
                property: "opacity"
                from: 0.9
                to: 0.2
                duration: 1000
                easing.type: Easing.InOutQuad
            }
            NumberAnimation {
                target: dragHighlight
                property: "opacity"
                from: 0.2
                to: 0.9
                duration: 1000
                easing.type: Easing.InOutQuad
            }
        }
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

        property bool isPressed: false
        property bool isDragging: false
        property point startPos: Qt.point(0, 0);

        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        anchors.fill: parent
        hoverEnabled: true
        enabled: true

        onPressed: function(mouse) {
            startPos = Qt.point(mouse.x, mouse.y);
            isPressed = true
        }

        onPositionChanged: function(mouse) {
            if (isPressed && !isDragging && (Math.abs(mouse.x - startPos.x) > 10 || Math.abs(mouse.y - startPos.y) > 10)) {
                hoverTimer.stop();
                buttonTooltip.checkHide(true);
                isDragging = true;
                buttonGrid.draggedButton = buttonRect;
                buttonGrid.draggedButtonOriginalIndex = model.index;
                buttonGrid.dragStartPos = startPos;
            }
        }

        onReleased: function(mouse) {
            isPressed = false;
            if (isDragging) {
                // Manually trigger grid's release handler
                isDragging = false;
                buttonGrid.handleDragRelease();
                mouse.accepted = true;
            } else {
                Qt.callLater(function() {
                    hoverTimer.stop();
                    buttonTooltip.checkHide(true);
                });

                if (mouse.button === Qt.LeftButton) {
                    desktopButtonClicked(buttonRect.number);
                    mouse.accepted = true;
                } else if (mouse.button === Qt.MiddleButton) {
                    if (config.WheelClickRemoves) {
                        buttonMiddleClick(buttonRect);
                        mouse.accepted = true;
                    }
                }
            }
        }

        onContainsMouseChanged: {
            applyOpacityRules();
            applyColorRules();
            desktopButtonHovered(buttonRect);
        }

        onEntered: {
            if (!isDragging) {
                hoverTimer.start();
            }
        }

        onExited: {
            hoverTimer.stop();
            Utils.delay(300, function () {
                buttonTooltip.checkHide(false);
            }, _mouseArea);
        }

        Timer {
            id: hoverTimer

            interval: tooltipDelay
            repeat: false

            onTriggered: {
                Qt.callLater(function() {
                    if (!ignoreMouseArea && !buttonGrid.isRenamingDesktop) {
                        buttonTooltip.show();
                    }
                });
            }
        }

    }

    function applyColorRules() {
        let indicatorColor = Kirigami.Theme.textColor;

        if (isCurrent) {
            //indicatorColor = config.IndicatorColorCurrent || PlasmaCore.Theme.highlightColor
            indicatorColor = config.IndicatorColorCurrent || systemPalette.highlight
        }
        if (isEmpty && config.IndicatorColorIdle) {
            indicatorColor = config.IndicatorColorIdle;
        }
        if (!isEmpty && config.IndicatorColorOccupied) {
            indicatorColor = config.IndicatorColorOccupied;
        }
        if (isUrgent) {
            indicatorColor = "#e6520c"
            if (config.IndicatorColorAttention) {
                indicatorColor = config.IndicatorColorAttention;
            }
        }

        let labelColor = config.IndicatorStyle === IndicatorStyles.UseLabels ? indicatorColor :
            (config.LabelColor || Kirigami.Theme.textColor);

        indicator.color = indicatorColor;
        label.color = labelColor;

        return "transparent";
    }

    function applyOpacityRules() {
        let indicatorStyle = config.IndicatorStyle;

        // Determine indicator opacity
        let indOpacity = 1;
        let lblOpacity = 1;
        if (isCurrent) {
            indOpacity = 1.0;
            lblOpacity = 1.0;
        } else if ((!ignoreMouseArea && _mouseArea.containsMouse) || isDragged) {
            indOpacity = (indicatorStyle === 5) ? 1.0 : 0.75;
        } else if (config.IndicatorKeepOpacity) {
            const hasCustomColor = (isCurrent && config.IndicatorColorCurrent) ||
                (isEmpty && config.IndicatorColorIdle) ||
                (!isEmpty && config.IndicatorColorOccupied) ||
                (isUrgent && config.IndicatorColorAttention);
            if (hasCustomColor) {
                indOpacity = 1.0;
            } else if (!isEmpty && config.IndicatorDistinctOccupied) {
                indOpacity = (indicatorStyle === 5) ? 1.0 : 0.5;
            } else {
                indOpacity = (indicatorStyle === 5) ? 0.5 : 0.25;
            }
        } else if (!isEmpty && config.IndicatorDistinctOccupied) {
            indOpacity = (indicatorStyle === 5) ? 1.0 : 0.5;
        } else {
            indOpacity = (indicatorStyle === 5) ? 0.5 : 0.25;
        }

        // Determine label opacity
        if (indicatorStyle === IndicatorStyles.UseLabels) {
            lblOpacity = indOpacity; // Use same opacity as indicator when using label style
        } else if ((!ignoreMouseArea && _mouseArea.containsMouse) || isDragged) {
            lblOpacity = 1.0;
        } else if (!isCurrent && config.LabelDimIdle) {
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

        if (config.LabelStyle === IndicatorStyles.SideLine) {
            labelText = number + "";
        } else if (config.LabelStyle === IndicatorStyles.Block) {
            labelText = number + ": " + name;
        } else if (config.LabelStyle === IndicatorStyles.Rounded) {
            labelText = activeWindowName || name;
        } else if (config.LabelStyle === IndicatorStyles.FullSize) {
            if (config.LabelCustomFormat) {
                var format = config.LabelCustomFormat.trim();
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

        if (labelText.length > config.LabelMaxLength) {
            labelText = labelText.substr(0, config.LabelMaxLength - 1) + "…";
        }
        if (config.LabelUppercase) {
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
