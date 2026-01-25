import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami 2.20 as Kirigami

import "../../common" as Common
import "../../common/Utils.js" as Utils

Rectangle {
    id: windowItemRect

    property QtObject config: plasmoid.configuration

    property Item originalParent: null
    property point originalPos: Qt.point(0, 0)

    signal dragStarted()
    signal dragFinished()

    height: windowItemLayout.height + 16
    radius: 4

    SystemPalette { id: systemPalette }

    property color urgentColor:
        config.DesktopIndicatorsCustomColorForDesktopsNeedingAttention ?
            Qt.color(config.DesktopIndicatorsCustomColorForDesktopsNeedingAttention) :
            Qt.color("#e6520c");

    color: model.isActive ? Qt.rgba(systemPalette.highlight.r,
            systemPalette.highlight.g,
            systemPalette.highlight.b, 0.2) :
        model.isDemandingAttention ? Qt.rgba(urgentColor.r,
                urgentColor.g,
                urgentColor.b, 0.2) :
            "transparent"
    border.width: (model.isDemandingAttention || model.isActive) ? 1 : 0
    border.color: model.isActive ? systemPalette.highlight : urgentColor

    Behavior on opacity { NumberAnimation { duration: 150 } }
    Behavior on scale { NumberAnimation { duration: 150 } }

    MouseArea {
        id: itemMouseArea
        anchors.fill: parent
        z: 10  // Above content layer
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.NoButton  // Don't accept clicks, just hover

        property color origColor: "transparent"

        onEntered: {
            origColor = windowItemRect.color;
            let hoverColor = model.isDemandingAttention ? urgentColor : systemPalette.highlight;
            windowItemRect.color = Qt.rgba(hoverColor.r, hoverColor.g, hoverColor.b, 0.2);
            windowItemRect.border.color = hoverColor
            windowItemRect.border.width = 1;
        }

        onExited: {
            windowItemRect.color = origColor
            if (!model.isActive && !model.isDemandingAttention) {
                windowItemRect.border.width = 0;
            }
        }
    }

    MouseArea {
        id: dragMouseArea
        anchors.fill: parent
        z: 11  // Above hover MouseArea to capture clicks

        property bool isDragging: false
        property point startPos
        property Item draggedItem: null
        property Item draggedItemPlaceholder: null
        property point draggedItemOffset: Qt.point(0, 0);
        property point draggedItemStartPos: Qt.point(0, 0);
        property int bottomOfButton: 0

        onPressed: function(mouse) {
            startPos = Qt.point(mouse.x, mouse.y);
        }

        onPositionChanged: function(mouse) {
            if (!isDragging && (Math.abs(mouse.x - startPos.x) > 10 || Math.abs(mouse.y - startPos.y) > 10)) {
                dragOverlay.visible = true;
                isDragging = true;
                dragStarted();
                windowItemRect.opacity = 0;

                createDragVisual();
                createDragPlaceholder();
            }

            if (isDragging && draggedItem) {
                updateDragVisual();
                var globalPos = backend.getCursorPosition();
                checkForDropTarget(globalPos);
            }
        }

        onReleased: function(mouse) {
            if (isDragging) {
                var globalPos = backend.getCursorPosition();
                isDragging = false;
                if (handleDrop(globalPos)) {
                    draggedItem.destroy();
                    draggedItemPlaceholder.destroy();
                    draggedItem = null;
                    dragOverlay.visible = false;
                    dragFinished();
                    return;
                }

                    let xAnimation = Qt.createQmlObject(`
                    import QtQuick 2.15
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutCubic
                    }
                `, draggedItem);

                    let yAnimation = Qt.createQmlObject(`
                    import QtQuick 2.15
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutCubic
                    }
                `, draggedItem);

                    let scaleAnimation = Qt.createQmlObject(`
                    import QtQuick 2.15
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutCubic
                    }
                `, draggedItem);

                xAnimation.target = draggedItem;
                xAnimation.property = "x";
                xAnimation.to = draggedItemStartPos.x;

                yAnimation.target = draggedItem;
                yAnimation.property = "y";
                yAnimation.to = draggedItemStartPos.y;

                scaleAnimation.target = draggedItem;
                scaleAnimation.property = "scale";
                scaleAnimation.to = 1.1;

                let animationsCompleted = 0;

                function onAnimationFinished() {
                    animationsCompleted++;
                    if (animationsCompleted === 3) {
                        draggedItem.destroy();
                        draggedItemPlaceholder.destroy();
                        windowItemRect.opacity = 1;
                        draggedItem = null;
                        dragOverlay.visible = false;

                        xAnimation.destroy();
                        yAnimation.destroy();
                        scaleAnimation.destroy();
                    }
                }

                xAnimation.finished.connect(onAnimationFinished);
                yAnimation.finished.connect(onAnimationFinished);
                scaleAnimation.finished.connect(onAnimationFinished);

                // Start both animations
                xAnimation.start();
                yAnimation.start();
                scaleAnimation.start();

                dragFinished();
            }
            else {
                Common.TaskManager.activateWindow(model.winId, model.desktopId, model.activityId);
                hide();
                mouse.accepted = true;
            }
        }

        function createDragVisual() {
            let component = Qt.createComponent("WindowItemDragVisual.qml");

            if (component.status === Component.Ready) {
                draggedItem = component.createObject(dragOverlayContent, {
                    "appName": model.appName,
                    "iconName": model.iconName,
                    "isActive": model.isActive,
                    "genericName": model.genericName,
                    "isDemandingAttention": model.isDemandingAttention,
                    "activityId": model.activityId,
                    "desktopId": model.desktopId,
                    "width": windowItemRect.width,
                    "height": windowItemRect.height,
                });

                if (draggedItem) {
                    let clickPos = backend.getRelativeCursorPosition();
                    draggedItemOffset = windowItemRect.mapFromGlobal(clickPos.x, clickPos.y);
                    updateDragVisual();
                    draggedItemStartPos.x = draggedItem.x;
                    draggedItemStartPos.y = draggedItem.y;
                } else {
                    console.log("Failed to create drag visual object");
                }
            } else {
                console.log("Component error:", component.errorString());
            }
        }

        function updateDragVisual() {
            let pos = backend.getRelativeCursorPosition();
            let screenOffset = backend.getRelativeScreenPosition();
            draggedItem.x = pos.x - draggedItemOffset.x - screenOffset.x;
            draggedItem.y = pos.y - draggedItemOffset.y - screenOffset.y;

            let offsetButtonBottom = bottomOfButton - screenOffset.y
            if (draggedItem.y < offsetButtonBottom) {
                draggedItem.y = offsetButtonBottom;
            }
            draggedItem.z = 100;
        }

        function createDragPlaceholder() {
            let component = Qt.createComponent("WindowItemDragPlaceholder.qml");

            if (component.status === Component.Ready) {
                draggedItemPlaceholder = component.createObject(windowItemRect.parent, {
                    "isDemandingAttention": model.isDemandingAttention,
                    "width": windowItemRect.width,
                    "height": windowItemRect.height,
                    "x": windowItemRect.x,
                    "y": windowItemRect.y
                });
            } else {
                console.log("Component error:", component.errorString());
            }
        }

        function checkForDropTarget(globalPos) {
            let targetButton = null;
            for (var uuid in buttonGrid.desktopButtonMap) {
                var button = buttonGrid.desktopButtonMap[uuid];
                if (isPointInButton(button, globalPos)) {
                    for (var i = 0; i < button.children.length; i++) {
                        if (button.children[i].hasOwnProperty('dragIsHovered')) {
                            button.children[i].dragIsHovered = true;
                            targetButton = button;
                            break;
                        }
                    }
                } else {
                    for (var j = 0; j < button.children.length; j++) {
                        if (button.children[j].hasOwnProperty('dragIsHovered')) {
                            button.children[j].dragIsHovered = false;
                            break;
                        }
                    }
                }
            }
            if (targetButton) {
                draggedItem.pulse = true;
            }
            else {
                draggedItem.pulse = false;
            }
        }

        function isPointInButton(button, globalPos) {
            try {
                var buttonGlobal = button.mapToGlobal(0, 0);
                var isInside = globalPos.x >= buttonGlobal.x &&
                    globalPos.x <= buttonGlobal.x + button.width &&
                    globalPos.y >= buttonGlobal.y &&
                    globalPos.y <= buttonGlobal.y + button.height;

                bottomOfButton = buttonGlobal.y + button.height;
                return isInside;
            } catch (e) {
                console.log("Error in isPointInButton:", e);
                return false;
            }
        }

        function handleDrop(globalPos) {
            for (let uuid in buttonGrid.desktopButtonMap) {
                let button = buttonGrid.desktopButtonMap[uuid];
                if (isPointInButton(button, globalPos) && uuid != dragMouseArea.draggedItem.desktopId) {
                    let desktopList = [uuid];
                    Common.TaskManager.requestVirtualDesktops(model.winId, model.desktopId, desktopList, model.activityId);
                    clearAllHighlights();

                    return true;
                }
            }

            clearAllHighlights();
            return false;
        }

        function clearAllHighlights() {
            for (var uuid in buttonGrid.desktopButtonMap) {
                var button = buttonGrid.desktopButtonMap[uuid];
                for (var i = 0; i < button.children.length; i++) {
                    if (button.children[i].hasOwnProperty('dragIsHovered')) {
                        button.children[i].dragIsHovered = false;
                        break;
                    }
                }
            }
        }
    }

    RowLayout {
        id: windowItemLayout
        z: 3
        Layout.minimumWidth: 300
        Layout.maximumWidth: 500
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 8
        }
        spacing: 10

        Item {
            width: 22
            height: 22

            Kirigami.Icon {
                anchors.fill: parent
                source: model.iconName
                visible: true
            }
        }

        Label {
            Layout.fillWidth: true
            text: model.appName
            elide: Text.ElideRight
            font.weight: model.isActive ? Font.Bold : Font.Normal
            color: Kirigami.Theme.textColor
        }

        Label {
            visible: model.isActive
            text: "Active"
            color: systemPalette.highlight
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            font.italic: true
        }
        Label {
            visible: model.isDemandingAttention
            text: {
                if (backend.getCurrentActivityId() != model.activityId) {
                    return "Urgent: " + backend.getActivityName(model.activityId);
                }

                return "Urgent"
            }
            color: urgentColor
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            font.italic: true
        }
    }
}