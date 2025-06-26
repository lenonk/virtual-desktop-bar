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
    property bool isDummy: false
    property string name: ""
    property int number: 0
    property int modelIdx: -1
    property string uuid: ""
    property string activeWindowName: ""
    property Item buttonGrid: null

    property alias mouseArea: _mouseArea
    property alias borderCanvas: _borderCanvas

    property int verticalMargins: 5
    property int horizontalPadding: 5 + (Common.LayoutProps.isVerticalOrientation ? 0 : config.DesktopButtonsSpacing)
    property int verticalPadding: 5 + (Common.LayoutProps.isVerticalOrientation ? config.DesktopButtonsSpacing : 0)

    Layout.fillHeight: !Common.LayoutProps.isVerticalOrientation
    Layout.fillWidth: Common.LayoutProps.isVerticalOrientation
    Layout.topMargin: verticalMargins
    Layout.bottomMargin: verticalMargins

    implicitHeight: label.implicitHeight + 2 * verticalPadding
    implicitWidth: isDummy ? 1 : label.implicitWidth + 2 * horizontalPadding

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

    Canvas {
        id: _borderCanvas
        anchors.fill: parent
        visible: false

        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            ctx.strokeStyle = systemPalette.highlight;
            ctx.lineWidth = 2;
            ctx.setLineDash([3, 2]); // 6px dash, 4px gap
            ctx.strokeRect(1, 1, width - 2, height - 2);
        }

        onVisibleChanged: {
            requestPaint();
        }

        Component.onCompleted: {
            requestPaint();
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
        visible: dragOverlay.visible && !dragHighlight.visible && !isDummy
        color: "transparent"

        border.width: 1
        border.color: systemPalette.highlight
    }

    Rectangle {
        id: dragHighlight

        property bool dragIsHovered: false

        anchors.fill: parent
        visible: dragIsHovered && !isDummy

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
        visible: !isDummy
    }

    DesktopButtonLabel {
        id: label
        visible: !isDummy

        text: getButtonLabel()
    }

    MouseArea {
        id: _mouseArea

        property bool isPressed: false
        property bool isDragging: false
        property point startPos: Qt.point(0, 0);
        property point draggedItemStartPos: Qt.point(0, 0);
        property Item draggedItemPlaceholder: null

        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        anchors.fill: parent
        hoverEnabled: true
        // enabled: true
        enabled: !isDummy

        onPressed: function(mouse) {
            startPos = Qt.point(mouse.x, mouse.y);
            draggedItemStartPos = Qt.point(buttonRect.x, buttonRect.y);
            isPressed = true
        }

        onPositionChanged: function(mouse) {
            if (isPressed && !isDragging && (Math.abs(mouse.x - startPos.x) > 10 || Math.abs(mouse.y - startPos.y) > 10)) {
                hoverTimer.stop();
                buttonTooltip.checkHide(true);
                isDragging = true;
                indicator.visible = false;
                label.visible = false;
                dragBorderHighlight.visible = false;
                dragHighlight.visible = false;

                buttonRect.color = "transparent";
                buttonRect.border.width = 1;
                buttonRect.border.color = systemPalette.highlight;
                buttonRect.opacity = 0.5;

                dragOverlay.visible = true;
                // createDragPlaceholder();
                createDragVisual();
            }

            if (isDragging) {
                // let layoutPos = buttonRect.mapToItem(desktopButtonGrid, mouse.x, mouse.y);
                // buttonRect.x = layoutPos.x - startPos.x;
                updateDragVisual();
                checkForDropTarget(backend.getCursorPosition());
            }
        }

        onReleased: function(mouse) {
            isPressed = false;
            if (isDragging) {
                var globalPos = backend.getCursorPosition();
                isDragging = false;
                if (handleDrop(globalPos)) {

                }
                else {
                    // buttonRect.x = draggedItemStartPos.x;
                    // buttonRect.y = draggedItemStartPos.y;
                    restoreOriginalAppearance();
                }

                draggedItemPlaceholder.destroy();
                draggedItemPlaceholder = null;
                dragOverlay.visible = false;
            }
            else {
                Qt.callLater(function() {
                    hoverTimer.stop();
                    buttonTooltip.checkHide(true);
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
        }

        onContainsMouseChanged: {
            applyOpacityRules();
            applyColorRules();
            desktopButtonHovered(buttonRect);
        }

        onEntered: {
            if (!dragOverlay.visible && !isDragging) {
                hoverTimer.start();
            }
        }

        onExited: {
            if (!dragOverlay.visible) {
                hoverTimer.stop();
                Utils.delay(100, function () {
                    buttonTooltip.checkHide(false);
                }, _mouseArea);
            }
        }

        Timer {
            id: hoverTimer

            interval: tooltipDelay
            repeat: false

            onTriggered: {
                Qt.callLater(function() {
                    if (!ignoreMouseArea) {
                        buttonTooltip.show();
                    }
                });
            }
        }

        function checkForDropTarget(globalPos) {
            for (let uuid in buttonGrid.desktopButtonMap) {
                let dummy = buttonGrid.desktopButtonMap[uuid];
                if (isPointInDummy(dummy, globalPos)) {
                    const itemX = draggedItemStartPos.x;
                    const itemWidth = buttonRect.width;
                    if (Math.abs(dummy.x - itemX) <= 5 || Math.abs(dummy.x - (itemX + itemWidth)) <= 5) {
                        continue;
                    }
                    dummy.Layout.preferredWidth = buttonRect.width;
                    dummy.borderCanvas.visible = true;
                    break;
                } else {
                    if (dummy.isDummy === true) {
                        dummy.Layout.preferredWidth = 1;
                        dummy.borderCanvas.visible = false;
                    }
                }
            }
        }

        function isPointInDummy(button, globalPos) {
            try {
                if (!button.isDummy) { return false; }
                var dummyGlobal = button.mapToGlobal(0, 0);
                var isInside = globalPos.x >= dummyGlobal.x - 5 &&
                    globalPos.x <= dummyGlobal.x + 5 + button.width &&
                    globalPos.y >= dummyGlobal.y &&
                    globalPos.y <= dummyGlobal.y + button.height;

                return isInside;
            } catch (e) {
                console.log("Error in isPointInButton:", e);
                return false;
            }
        }

        function handleDrop(globalPos) {
            for (let uuid in buttonGrid.desktopButtonMap) {
                let button = buttonGrid.desktopButtonMap[uuid];
                if (isPointInDummy(button, globalPos)) {
                    if (button.number > buttonRect.number) {
                        console.log(buttonRect.uuid, ": Number:", buttonRect.number, "Moved to the right");
                        // TODO: Move all the buttons to the left down one.  For instance, if moving desktop 1 to
                        // desktop 3, Move all windows from desktop 2 to desktop 1, then rename desktop 1 to desktop 2.
                        // Repeat for 3 -> 2, then repeat for dragged button -> desktop 3.  The trick is going to be
                        // moving the correct windows from the dragged desktop to desktop 3, since we've already moved
                        // the windows from desktop 2 to desktop 1, and we're dragging desktop 1.  We probably need to
                        // just make a copy of all the windows on desktop 1 when we start dragging and move those to
                        // desktop 3 on drop. Desktop 1 will briefly have all the windows from desktop 1 and 2, but
                        // ok as long as we know which ones to move to 3 in the end.
                    }
                    else {
                        console.log(buttonRect.uuid, ": Number:", buttonRect.number, "Moved to the left");
                        // TODO: Do the above, but in reverse, moving all the desktops with numbers greater than the
                        // drop zone to the right, started with the last desktop.
                    }
                    return true;
                }
            }

            return false;
        }

        function createDragVisual() {
            let component = Qt.createComponent("DesktopButtonDragPlaceholder.qml");

            if (component.status === Component.Ready) {
                // draggedItemPlaceholder = component.createObject(desktopButtonGrid, {
                draggedItemPlaceholder = component.createObject(dragOverlayContent, {
                    "width": buttonRect.width,
                    "height": buttonRect.height,
                    // "x": buttonRect.x,
                    // "y": buttonRect.y
                });
            } else {
                console.log("Component error:", component.errorString());
            }
        }
    }

    function updateDragVisual() {
        if (!draggedItemPlaceholder) return;

        let pos = backend.getRelativeCursorPosition();
        let screenOffset = backend.getRelativeScreenPosition();
        draggedItemPlaceholder.x = pos.x - startPos.x - screenOffset.x;
        draggedItemPlaceholder.y = pos.y - startPos.y - screenOffset.y;
        draggedItemPlaceholder.z = 100;
    }

    function restoreOriginalAppearance() {
        // Restore the original button appearance
        indicator.visible = !isDummy;
        label.visible = !isDummy;
        buttonRect.color = applyColorRules();
        buttonRect.opacity = applyOpacityRules();
        buttonRect.border.width = 0;

        // Re-enable drag highlights
        dragBorderHighlight.visible = dragOverlay.visible && !dragHighlight.visible && !isDummy;
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
