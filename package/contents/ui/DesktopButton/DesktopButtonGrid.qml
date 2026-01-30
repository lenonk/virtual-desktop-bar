import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import "../common" as Common

Item {
    id: desktopButtonGrid
    property QtObject config: plasmoid.configuration

    required property var container
    required property ListModel desktopInfoList

    property DesktopButton hoveredButton
    property bool commonSizeEnabled: config.ButtonCommonSize
    property var desktopButtonMap: ({})
    property int dropZoneIndex: -1  // Index of drop zone being hovered (-1 = none)
    property DesktopButton draggedButton: null
    property int draggedButtonOriginalIndex: -1
    property Item previewButton: null
    property point dragStartPos: Qt.point(0, 0)

    signal desktopButtonClicked(int number)
    signal desktopButtonHovered(DesktopButton button)
    signal buttonImplicitWidthChanged()

    GridLayout {
        id: gridLayout
        rowSpacing: 0
        columnSpacing: 0
        flow: Common.LayoutProps.isVerticalOrientation ? GridLayout.TopToBottom : GridLayout.LeftToRight

        anchors.centerIn: parent

        Layout.alignment: Qt.AlignCenter
        Layout.fillWidth: Common.LayoutProps.isVerticalOrientation
        Layout.fillHeight: !Common.LayoutProps.isVerticalOrientation

        Repeater {
            id: repeater
            model: desktopButtonGrid.desktopInfoList

            delegate: DesktopButton {
                id: delegateButton
                number: model.id + 1
                name: model.name
                uuid: model.uuid
                isCurrent: model.is_current
                buttonGrid: desktopButtonGrid

                property int dropZoneSpacingLeft: 0
                property int dropZoneSpacingRight: 0
                property int dropZoneSpacingTop: 0
                property int dropZoneSpacingBottom: 0

                // Override the Layout margins to add drop zone spacing
                Layout.leftMargin: dropZoneSpacingLeft
                Layout.rightMargin: dropZoneSpacingRight

                Behavior on dropZoneSpacingLeft {
                    NumberAnimation {
                        id: leftAnimation
                        duration: 150
                        easing.type: Easing.OutQuad
                    }
                }

                Behavior on dropZoneSpacingRight {
                    NumberAnimation {
                        id: rightAnimation
                        duration: 150
                        easing.type: Easing.OutQuad
                    }
                }

                Behavior on dropZoneSpacingTop {
                    NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
                }

                Behavior on dropZoneSpacingBottom {
                    NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
                }

                Connections {
                    target: leftAnimation
                    function onRunningChanged() {
                        if (!leftAnimation.running) {
                            let pos = buttonGrid.updatePreviewPosition();
                            if (pos) {
                                buttonGrid.createPreviewButton(pos.x, pos.y);
                            }
                        }
                    }
                }

                Connections {
                    target: rightAnimation
                    function onRunningChanged() {
                        if (!rightAnimation.running) {
                            let pos = buttonGrid.updatePreviewPosition();
                            if (pos) {
                                buttonGrid.createPreviewButton(pos.x, pos.y);
                            }
                        }
                    }
                }

                visible: draggedButton !== this || dropZoneIndex < 0

                Component.onCompleted: {
                    desktopButtonGrid.desktopButtonMap[uuid] = this;
                    Qt.callLater(updateButtonFirstAndLast);
                    Qt.callLater(updateGridSizes);
                }

                Component.onDestruction: {
                    delete desktopButtonGrid.desktopButtonMap[uuid];
                    Qt.callLater(updateButtonFirstAndLast);
                    Qt.callLater(updateGridSizes);
                }
            }
        }

        AddDesktopButton {
            Layout.fillWidth: Common.LayoutProps.isVerticalOrientation
            Layout.fillHeight: !Common.LayoutProps.isVerticalOrientation

            onAddDesktopButtonClicked: {
                container.addDesktop();
            }
        }

        onImplicitWidthChanged: { desktopButtonGrid.implicitWidth = implicitWidth; }
        onImplicitHeightChanged: { desktopButtonGrid.implicitHeight = implicitHeight; }
    }

    Timer {
        id: dragUpdateTimer
        interval: 16  // ~60fps
        repeat: true
        running: draggedButton !== null

        onTriggered: {
            if (draggedButton) {
                // Check if mouse button is released
                if (!backend.isMouseButtonPressed()) {
                    handleDragRelease();
                    return;
                }

                let globalPos = backend.getCursorPosition();
                let newDropZone = calculateDropZoneIndex(globalPos);
                if (newDropZone !== dropZoneIndex) {
                    dropZoneIndex = newDropZone;
                    updateDropZoneSpacing(newDropZone);
                }
            }
        }
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        hoverEnabled: false
        acceptedButtons: Qt.LeftButton
        enabled: draggedButton !== null

        onReleased: function(mouse) {
            handleDragRelease();
        }

        onWheel: function (wheel) {
            if (!config.WheelScrollSwitches) return;

            let button = null;
            if (Object.keys(desktopButtonMap).length > 0) {
                for (var i = 0; i < desktopInfoList.count; i++) {
                    button = desktopButtonMap[desktopInfoList.get(i).uuid];
                    if (button && button.isCurrent) {
                        break;
                    }
                }
            }

            if (!button) {
                console.log("No current desktop button found!");
                return;
            }

            let invert = config.WheelInvertDirection;
            invert = Common.LayoutProps.isVerticalOrientation ? !invert : invert;
            let wrap = config.WheelWrapAround;

            if (wheel.angleDelta.y > 0) {  // Scroll up
                if (invert) {
                    if (!button.isFirst || wrap) {
                        previousDesktop();
                    }
                } else {
                    if (!button.isLast || wrap) {
                        nextDesktop();
                    }
                }
            } else if (wheel.angleDelta.y < 0) {  // Scroll down
                if (invert) {
                    if (!button.isLast || wrap) {
                        nextDesktop();
                    }
                } else {
                    if (!button.isFirst || wrap) {
                        previousDesktop();
                    }
                }
            }

            wheel.accepted = true;
        }
    }

    onDesktopButtonClicked: function (number) {
        switchToDesktop(number);
    }

    onDesktopButtonHovered: function (button) {
        hoveredButton = button;
    }

    Component.onCompleted: {
        Qt.callLater(updateGridSizes);
    }

    function onButtonImplicitWidthChanged() {
        Qt.callLater(updateGridSizes);
    }

    onDesktopButtonMapChanged: {
        Qt.callLater(updateGridSizes);
    }

    onCommonSizeEnabledChanged: {
        Qt.callLater(updateGridSizes);
    }

    function updateButtonFirstAndLast() {
        // if (Object.keys(desktopButtonMap).length > 0) {
        //     for (var i = 0; i < desktopInfoList.count; i++) {
        //         let button = desktopButtonMap[desktopInfoList.get(i).uuid];
        //         if (i == 0) {
        //             button.isFirst = true;
        //             if (i != desktopInfoList.count - 1) button.isLast = false;
        //             else button.isLast = true;
        //
        //         } else if (i == desktopInfoList.count - 1) {
        //             if (i != 0) button.isFirst = false;
        //             else button.isFirst = true;
        //             button.isLast = true;
        //         } else {
        //             button.isFirst = false;
        //             button.isLast = false;
        //         }
        //     }
        // }
        for (var uuid in desktopButtonMap) {
            var button = desktopButtonMap[uuid];
            if (button && button.number == 1) {
                button.isFirst = true;
                if (desktopInfoList.count <= 1) button.isLast = true;
                else button.isLast = false;
            }
            else if (button && button.number == desktopInfoList.count) {
                button.isLast = true;
                if (desktopInfoList.count <= 1) button.isFirst = true;
                else button.isFirst = false;
            }
            else if (button) {
                button.isFirst = false;
                button.isLast = false;
            }
        }
    }

    function updateGridSizes() {
        if (config.ButtonCommonSize) {
            var maxWidth = 0;
            for (var uuid in desktopButtonMap) {
                var button = desktopButtonMap[uuid];
                if (button && button.implicitWidth > maxWidth) {
                    maxWidth = button.implicitWidth;
                }
            }

            for (var uuid in desktopButtonMap) {
                var button = desktopButtonMap[uuid];
                if (button) {
                    button.Layout.preferredWidth = maxWidth;
                }
            }
        } else {
            for (var uuid in desktopButtonMap) {
                var button = desktopButtonMap[uuid];
                if (button) {
                    button.Layout.preferredWidth = button.implicitWidth;
                }
            }
        }
    }

    function calculateDropZoneIndex(globalPos) {
        if (!draggedButton) return -1;

        let isVertical = Common.LayoutProps.isVerticalOrientation;
        let cursorPos = isVertical ? globalPos.y : globalPos.x;
        let originalIdx = draggedButtonOriginalIndex;

        // Build list of button positions (excluding dragged button)
        let positions = [];
        for (let i = 0; i < desktopInfoList.count; i++) {
            let uuid = desktopInfoList.get(i).uuid;
            let button = desktopButtonMap[uuid];
            if (!button || button === draggedButton) continue;

            let btnGlobal = button.mapToGlobal(0, 0);
            let btnPos = isVertical ? btnGlobal.y : btnGlobal.x;
            let btnSize = isVertical ? button.height : button.width;

            positions.push({
                index: i,
                start: btnPos,
                end: btnPos + btnSize,
                center: btnPos + btnSize / 2
            });
        }

        if (positions.length === 0) return -1;

        // Check if before first button
        if (cursorPos < positions[0].center) {
            let dropIdx = 0;
            // Ignore drop zone immediately to the left of dragged button
            if (dropIdx === originalIdx) return -1;
            return dropIdx;
        }

        // Check if after last button
        if (cursorPos > positions[positions.length - 1].center) {
            let dropIdx = desktopInfoList.count;
            // Ignore drop zone immediately to the right of dragged button
            if (dropIdx === originalIdx + 1) return -1;
            return dropIdx;
        }

        // Find which buttons the cursor is between
        for (let i = 0; i < positions.length - 1; i++) {
            if (cursorPos >= positions[i].center && cursorPos < positions[i + 1].center) {
                // Return the index after position[i]
                let dropIdx = positions[i].index + 1;
                // Ignore drop zones immediately adjacent to dragged button
                if (dropIdx === originalIdx || dropIdx === originalIdx + 1) return -1;
                return dropIdx;
            }
        }

        return -1;
    }

    function updateDropZoneSpacing(dropZoneIdx) {
        // Reset all button spacing
        for (let uuid in desktopButtonMap) {
            let button = desktopButtonMap[uuid];
            if (button) {
                button.dropZoneSpacingLeft = 0;
                button.dropZoneSpacingRight = 0;
                button.dropZoneSpacingTop = 0;
                button.dropZoneSpacingBottom = 0;
            }
        }

        if (!draggedButton || dropZoneIdx < 0) {
            // Destroy preview when leaving drop zone
            if (previewButton) {
                previewButton.destroy();
                previewButton = null;
            }
            return;
        }

        // Use exact button width for spacing - split between two adjacent buttons
        let fullSpacing = draggedButton.width;
        let halfSpacing = draggedButton.width / 2.0;
        let originalIdx = draggedButtonOriginalIndex;

        // Check if returning to original position
        let isReturningToOriginal = (dropZoneIdx === originalIdx || dropZoneIdx === originalIdx + 1);

        console.log("Spacing: dropZoneIdx =", dropZoneIdx, "originalIdx =", originalIdx,
                    "isReturningToOriginal =", isReturningToOriginal, "count =", desktopInfoList.count);

        // Add spacing around drop zone by finding buttons at those indices
        if (dropZoneIdx >= 0 && dropZoneIdx <= desktopInfoList.count) {
            if (Common.LayoutProps.isVerticalOrientation) {
                // Vertical orientation - not supported yet, only horizontal
            } else {
                // Special case: dragging first button back to position 0
                if (dropZoneIdx === 0 && originalIdx === 0) {
                    // The button at list index 1 is now visibly first - give it full left spacing
                    if (desktopInfoList.count > 1) {
                        let firstVisibleUuid = desktopInfoList.get(1).uuid;
                        let firstVisibleButton = desktopButtonMap[firstVisibleUuid];
                        if (firstVisibleButton) {
                            console.log("  Special case: first button return, giving spacing to idx=1");
                            firstVisibleButton.dropZoneSpacingLeft = fullSpacing;
                        }
                    }
                }
                // Special case: dragging last button back to last position
                else if (dropZoneIdx === desktopInfoList.count && originalIdx === desktopInfoList.count - 1) {
                    // The button at list index (count-2) is now visibly last - give it full right spacing
                    if (desktopInfoList.count > 1) {
                        let lastVisibleUuid = desktopInfoList.get(desktopInfoList.count - 2).uuid;
                        let lastVisibleButton = desktopButtonMap[lastVisibleUuid];
                        if (lastVisibleButton) {
                            console.log("  Special case: last button return, giving spacing to idx=" + (desktopInfoList.count - 2));
                            lastVisibleButton.dropZoneSpacingRight = fullSpacing;
                        }
                    }
                }
                // Normal cases
                else {
                    if (dropZoneIdx > 0) {
                        let beforeIdx = dropZoneIdx - 1;
                        let beforeUuid = desktopInfoList.get(beforeIdx).uuid;
                        let beforeButton = desktopButtonMap[beforeUuid];

                        if (beforeButton && beforeButton !== draggedButton) {
                            let isEndPosition = dropZoneIdx === desktopInfoList.count;
                            let spacing = (isEndPosition || isReturningToOriginal) ? fullSpacing : halfSpacing;

                            console.log("  beforeButton: idx=" + beforeIdx + " name=" + beforeButton.name + " spacing=" + spacing);
                            beforeButton.dropZoneSpacingRight = spacing;
                        }
                    }
                    if (dropZoneIdx < desktopInfoList.count) {
                        let afterIdx = dropZoneIdx;
                        let afterUuid = desktopInfoList.get(afterIdx).uuid;
                        let afterButton = desktopButtonMap[afterUuid];

                        if (afterButton && afterButton !== draggedButton) {
                            let isStartPosition = dropZoneIdx === 0;
                            let spacing = (isStartPosition || isReturningToOriginal) ? fullSpacing : halfSpacing;

                            console.log("  afterButton: idx=" + afterIdx + " name=" + afterButton.name + " spacing=" + spacing);
                            afterButton.dropZoneSpacingLeft = spacing;
                        }
                    }
                }
            }
        }
    }

    function handleDragRelease() {
        if (!draggedButton) return;

        let dropZone = dropZoneIndex;

        desktopButtonGrid.visible = false;

        // Reset button's drag state first
        draggedButton.mouseArea.isDragging = false;
        draggedButton.mouseArea.isPressed = false;

        if (dropZone >= 0) {
            let originalIndex = draggedButtonOriginalIndex;
            let targetIndex = dropZone;

            // Adjust target index if dropping after the dragged item's original position
            if (dropZone > originalIndex) {
                targetIndex = dropZone - 1;
            }

            // Insert desktop at new position by rotating all desktops in between
            if (targetIndex >= 0 && targetIndex < desktopInfoList.count && targetIndex !== originalIndex) {
                let activityId = backend.getCurrentActivityId();

                // Collect all desktop info and windows for the range we're shifting
                let desktopData = [];
                let minIdx = Math.min(originalIndex, targetIndex);
                let maxIdx = Math.max(originalIndex, targetIndex);

                for (let i = minIdx; i <= maxIdx; i++) {
                    let desktop = desktopInfoList.get(i);
                    let windows = Common.TaskManagerUtils.getWindowsForDesktop(desktop.uuid, activityId);
                    desktopData.push({
                        index: i,
                        uuid: desktop.uuid,
                        name: desktop.name,
                        isCurrent: desktop.is_current,
                        windows: windows
                    });
                }

                // Rotate desktop names to insert dragged desktop at target position
                if (originalIndex < targetIndex) {
                    // Dragging right: shift desktops left, dragged goes to end
                    for (let i = 0; i < desktopData.length - 1; i++) {
                        backend.setDesktopName(desktopData[i].uuid, desktopData[i + 1].name);
                    }
                    backend.setDesktopName(desktopData[desktopData.length - 1].uuid, desktopData[0].name);
                } else {
                    // Dragging left: shift desktops right, dragged goes to start
                    for (let i = desktopData.length - 1; i > 0; i--) {
                        backend.setDesktopName(desktopData[i].uuid, desktopData[i - 1].name);
                    }
                    backend.setDesktopName(desktopData[0].uuid, desktopData[desktopData.length - 1].name);
                }

                // Rotate windows to match the desktop name rotation
                if (originalIndex < targetIndex) {
                    // Move each desktop's windows to the previous desktop
                    for (let i = 0; i < desktopData.length - 1; i++) {
                        let targetUuid = desktopData[i].uuid;
                        let sourceWindows = desktopData[i + 1].windows;
                        for (let w = 0; w < sourceWindows.length; w++) {
                            Common.TaskManagerUtils.requestVirtualDesktops(
                                sourceWindows[w].winId,
                                desktopData[i + 1].uuid,
                                [targetUuid],
                                activityId
                            );
                        }
                    }
                    // Move original desktop's windows to the end
                    let sourceWindows = desktopData[0].windows;
                    let targetUuid = desktopData[desktopData.length - 1].uuid;
                    for (let w = 0; w < sourceWindows.length; w++) {
                        Common.TaskManagerUtils.requestVirtualDesktops(
                            sourceWindows[w].winId,
                            desktopData[0].uuid,
                            [targetUuid],
                            activityId
                        );
                    }
                } else {
                    // Move each desktop's windows to the next desktop
                    for (let i = desktopData.length - 1; i > 0; i--) {
                        let targetUuid = desktopData[i].uuid;
                        let sourceWindows = desktopData[i - 1].windows;
                        for (let w = 0; w < sourceWindows.length; w++) {
                            Common.TaskManagerUtils.requestVirtualDesktops(
                                sourceWindows[w].winId,
                                desktopData[i - 1].uuid,
                                [targetUuid],
                                activityId
                            );
                        }
                    }
                    // Move original desktop's windows to the start
                    let sourceWindows = desktopData[desktopData.length - 1].windows;
                    let targetUuid = desktopData[0].uuid;
                    for (let w = 0; w < sourceWindows.length; w++) {
                        Common.TaskManagerUtils.requestVirtualDesktops(
                            sourceWindows[w].winId,
                            desktopData[desktopData.length - 1].uuid,
                            [targetUuid],
                            activityId
                        );
                    }
                }

                // Handle current desktop tracking
                let sourceIsCurrent = desktopData.find(d => d.index === originalIndex).isCurrent;
                if (sourceIsCurrent) {
                    backend.setCurrentDesktop(targetIndex + 1);
                } else {
                    // If another desktop in the range was current, update it
                    for (let i = 0; i < desktopData.length; i++) {
                        if (desktopData[i].isCurrent) {
                            let newIdx = desktopData[i].index;
                            if (originalIndex < targetIndex) {
                                // Shifted left
                                if (newIdx > originalIndex && newIdx <= targetIndex) {
                                    newIdx--;
                                }
                            } else {
                                // Shifted right
                                if (newIdx >= targetIndex && newIdx < originalIndex) {
                                    newIdx++;
                                }
                            }
                            backend.setCurrentDesktop(newIdx + 1);
                            break;
                        }
                    }
                }
            }
        }

        // Reset drop zone spacing and destroy preview
        updateDropZoneSpacing(-1);

        // Reset everything
        draggedButton = null;
        draggedButtonOriginalIndex = -1;
        dropZoneIndex = -1;

        Qt.callLater(desktopButtonGrid.visible = true);
    }

    function updatePreviewPosition() {
        if (!draggedButton) return null;

        let originalIdx = draggedButtonOriginalIndex;

        console.log("updatePreviewPosition: dropZoneIdx=" + dropZoneIndex + " originalIdx=" + originalIdx);

        // Build list of visible buttons
        let visibleButtons = [];
        for (let i = 0; i < desktopInfoList.count; i++) {
            let uuid = desktopInfoList.get(i).uuid;
            let button = desktopButtonMap[uuid];
            if (button && button !== draggedButton) {
                console.log("  [" + i + "] Visible button: " + button.name + " x=" + button.x + " width=" + button.width);
                visibleButtons.push({
                    index: i,
                    button: button,
                    name: button.name
                });
            } else if (button === draggedButton) {
                console.log("  [" + i + "] DRAGGED button (skipped): " + button.name);
            }
        }

        // Determine target visible index
        let targetVisibleIdx = dropZoneIndex;
        if (dropZoneIndex > originalIdx) {
            targetVisibleIdx = dropZoneIndex - 1;
        }

        console.log("  visibleButtons.length=" + visibleButtons.length + " targetVisibleIdx=" + targetVisibleIdx);

        let xPos = 0;
        let yPos = draggedButton.y;

        if (targetVisibleIdx === 0) {
            // Preview goes at the very start (position 0)
            xPos = 0;
            console.log("  Preview at start (x=0)");
        } else if (targetVisibleIdx >= visibleButtons.length) {
            // Preview goes after last visible button
            if (visibleButtons.length > 0) {
                let lastBtn = visibleButtons[visibleButtons.length - 1].button;
                xPos = lastBtn.x + lastBtn.width;
                console.log("  Preview at end after " + visibleButtons[visibleButtons.length - 1].name + " x=" + xPos);
            }
        } else {
            // Preview goes between buttons - position after the button before it
            let beforeBtn = visibleButtons[targetVisibleIdx - 1].button;
            xPos = beforeBtn.x + beforeBtn.width;
            console.log("  Preview after " + visibleButtons[targetVisibleIdx - 1].name + " x=" + xPos);
        }

        // If preview already exists, update its position
        if (previewButton) {
            console.log("  Updating existing preview position to x=" + xPos);
            previewButton.x = xPos;
            previewButton.y = yPos;
            return null;
        }

        // Return position for new preview
        return { x: xPos, y: yPos };
    }

    function createPreviewButton(xPos, yPos) {
        // Destroy existing preview first
        if (previewButton) {
            previewButton.destroy();
            previewButton = null;
        }

        if (!draggedButton) return;

        console.log("createPreviewButton: creating at x=" + xPos + " y=" + yPos);

        let qmlString = `
            import QtQuick

            Item {
                id: previewItem
                opacity: 1.0
                z: 999

                Image {
                    id: snapshot
                    anchors.fill: parent
                }
            }
        `;

        previewButton = Qt.createQmlObject(qmlString, desktopButtonGrid, "previewButton");
        if (previewButton) {
            previewButton.width = draggedButton.width;
            previewButton.height = draggedButton.height;
            previewButton.x = xPos;
            previewButton.y = yPos;

            // Capture the button's appearance
            draggedButton.grabToImage(function(result) {
                if (previewButton) {
                    previewButton.children[0].source = result.url;
                }
            });
        }
    }
}