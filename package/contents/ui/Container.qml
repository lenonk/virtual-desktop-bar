import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.virtualdesktopbar 1.0
import "common/Utils.js" as Utils
import "common" as Common
import "."

Item {
    id: root

    property var desktopButtonList: []
    property Item lastHoveredButton
    property Item lastDesktopButton
    property Item currentDesktopButton
    property Item largestDesktopButton
    property int numberOfVisibleDesktopButtons
    property bool isDragging: false
    property Item draggedDesktopButton
    readonly property int pressToDragDuration: 300

    anchors.fill: parent

    VirtualDesktopBar {
        id: backend
    }

    GridLayout {
        id: mainLayout
        anchors.fill: parent
        rowSpacing: 0
        columnSpacing: 0
        flow: Common.LayoutProps.isVerticalOrientation ? GridLayout.TopToBottom : GridLayout.LeftToRight
        Layout.minimumWidth: 200

        GridLayout {
            id: desktopButtonContainer
            Layout.fillWidth: true
            Layout.fillHeight: true
            rowSpacing: parent.rowSpacing
            columnSpacing: parent.columnSpacing
            flow: parent.flow

            Repeater {
                id: buttonRepeater
                model: backend.requestDesktopInfoList()
                delegate: DesktopButton {
                    visible: true
                    container: root
                    property var desktopInfo: modelData
                    number: modelData.id
                    name: modelData.name
                    windowNameList: modelData.window_name_list
                    isVisible: modelData.is_visible
                    isCurrent: modelData.is_current

                    Component.onCompleted: {
                        if (!root.desktopButtonList[index]) {
                            root.desktopButtonList[index] = this;
                        }
                    }
                    Component.onDestruction: {
                        root.desktopButtonList[index] = null;
                    }
                }
            }
        }

        AddDesktopButton {
            Layout.fillWidth: Common.LayoutProps.isVerticalOrientation
            Layout.fillHeight: !Common.LayoutProps.isVerticalOrientation
        }
    }

    function update(desktopInfoList) {
        console.log("virtualdesktopbar: dil.length: " + desktopInfoList.length)
        let synchronousUpdate = true;
        let difference = desktopInfoList.length - desktopButtonList.length;

        if (difference > 0) {
            console.log("virtualdesktopbar: Adding desktop button");
            addDesktopButtons(difference);
        } else if (difference < 0) {
            removeDesktopButtons(desktopInfoList);
            synchronousUpdate = !config.AnimationsEnable;
        }

        if (synchronousUpdate) {
            console.log("virtualdesktopbar: Updating desktop buttons");
            updateDesktopButtons(desktopInfoList);
        }

        lastDesktopButton = buttonRepeater.itemAt(desktopButtonList.length - 1);
        currentDesktopButton = desktopButtonList.find(button => button && button.isCurrent) || null;
    }

    function addDesktopButtons(difference) {
        let init = desktopButtonList.length === 0;

        for (let i = 0; i < difference; i++) {
            desktopButtonList.push(null);
        }

        console.log("virtualdesktopbar: dbl length: " + desktopButtonList.length);

        if (!init && difference !== 0 && !config.DynamicDesktopsEnable) {
            if (config.AddingDesktopsSwitchTo) {
                Utils.delay(100, function() {
                    backend.showDesktop(desktopButtonList.length);
                }, root);
            }
            if (config.AddingDesktopsPromptToRename) {
                Utils.delay(100, function() {
                    let lastButton = buttonRepeater.itemAt(desktopButtonList.length - 1);
                    renamePopup.show(lastButton);
                }, root);
            }
        }
    }

    function removeDesktopButtons(desktopInfoList) {
       desktopButtonList = desktopButtonList.slice(0, desktopInfoList.length);
    }

    function getRemovedDesktopButtonIndexList(desktopInfoList) {
        var removedDesktopButtonIndexList = [];

        for (var i = 0; i < desktopButtonList.length; i++) {
            var desktopButton = desktopButtonList[i];

            var keepDesktopButton = false;
            for (var j = 0; j < desktopInfoList.length; j++) {
                var desktopInfo = desktopInfoList[j];
                if (desktopButton.id === desktopInfo.id) {
                    keepDesktopButton = true;
                    break;
                }
            }
            if (!keepDesktopButton) {
                removedDesktopButtonIndexList.push(i);
            }
        }

        return removedDesktopButtonIndexList;
    }

    function updateDesktopButtons(desktopInfoList) {
        for (let i = 0; i < desktopButtonList.length; i++) {
            let button = buttonRepeater.itemAt(i);
            if (button) {
                button.number = desktopInfoList[i].number;
                button.isCurrent = desktopInfoList[i].isCurrent;
            }
        }
    }

    function updateLargestDesktopButton() {
        let temp = largestDesktopButton;

        for (let i = 0; i < desktopButtonList.length; i++) {
            const desktopButton = desktopButtonList[i];
            // Skip invalid or null buttons
            if (!desktopButton || !desktopButton._label) {
                continue;
            }
            // Compare implicitWidth, ensuring temp._label exists
            if (!temp || !temp._label || temp._label.implicitWidth < desktopButton._label.implicitWidth) {
                temp = desktopButton;
            }
        }

        if (temp !== largestDesktopButton) {
            largestDesktopButton = temp;
        }
    }

    function updateNumberOfVisibleDesktopButtons() {
        numberOfVisibleDesktopButtons = desktopButtonList.filter(button => {
            return button && button.visible; // Use 'visible' or 'isVisible' as defined
        }).length;
    }

    MouseArea {
        anchors.fill: parent
        propagateComposedEvents: true

        readonly property int wheelDeltaLimit: 120
        property int currentWheelDelta: 0

        onClicked: {
            mouse.accepted = isDragging;
        }

        onPressed: {
            const initialDesktopButton = desktopButtonContainer.childAt(mouse.x, mouse.y);
            if (!initialDesktopButton || !initialDesktopButton.number) {
                return; // Ensure it's a DesktopButton with a number property
            }

            Utils.delay(pressToDragDuration, function() {
                if (!pressed) {
                    return;
                }

                const desktopButton = desktopButtonContainer.childAt(mouse.x, mouse.y);
                if (desktopButton && desktopButton === initialDesktopButton) {
                    isDragging = true;
                    draggedDesktopButton = desktopButton;
                }
            }, root);
        }

        onPositionChanged: {
            if (isDragging) {
                const desktopButton = desktopButtonContainer.childAt(mouse.x, mouse.y);
                if (!desktopButton || !desktopButton.number || desktopButton === draggedDesktopButton) {
                    return; // Skip if not a valid button or same as dragged
                }

                const maxOffset = desktopButton.width * 0.3;
                const centerPos = desktopButton.x + desktopButton.width / 2;
                if (mouse.x >= centerPos - maxOffset && mouse.x <= centerPos + maxOffset) {
                    backend.replaceDesktops(draggedDesktopButton.number, desktopButton.number);
                    draggedDesktopButton = desktopButton;
                }
            }
        }

        onReleased: {
            if (isDragging) {
                draggedDesktopButton = null;
                Qt.callLater(function() {
                    isDragging = false;
                });
            }
        }

        onWheel: {
            if (!config.MouseWheelSwitchDesktopOnScroll) {
                return;
            }

            let desktopNumber = 0;
            let change = wheel.angleDelta.y || wheel.angleDelta.x;
            if (!config.MouseWheelInvertDesktopSwitchingDirection) {
                change = -change;
            }

            currentWheelDelta += change;

            if (currentWheelDelta >= wheelDeltaLimit) {
                currentWheelDelta = 0;
                if (currentDesktopButton && currentDesktopButton.number < desktopButtonList.length) {
                    desktopNumber = currentDesktopButton.number + 1;
                } else if (config.MouseWheelWrapDesktopNavigationWhenScrolling) {
                    desktopNumber = 1;
                }
            }

            if (currentWheelDelta <= -wheelDeltaLimit) {
                currentWheelDelta = 0;
                if (currentDesktopButton && currentDesktopButton.number > 1) {
                    desktopNumber = currentDesktopButton.number - 1;
                } else if (config.MouseWheelWrapDesktopNavigationWhenScrolling) {
                    desktopNumber = desktopButtonList.length;
                }
            }

            if (desktopNumber > 0) {
                if (config.TooltipsEnable) {
                    tooltip.visible = false;
                }
                backend.showDesktop(desktopNumber);
            }
        }
    }
}
