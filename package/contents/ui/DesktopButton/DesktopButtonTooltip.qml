import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami 2.20 as Kirigami
import Qt5Compat.GraphicalEffects

import "../common" as Common
import "../common/Utils.js" as Utils
import "TooltipWindowList"

Item {
    id: tooltipRoot

    property QtObject config: plasmoid.configuration

    readonly property int animationDuration: 350

    property var sourceButton: null
    property bool isHovered: false
    property Item buttonGrid: null

    PlasmaCore.Dialog {
        id: tooltip

        type: PlasmaCore.Dialog.Tooltip
        location: plasmoid.location
        visible: false

        width: tooltipBackground.implicitWidth
        height: tooltipBackground.implicitHeight

        mainItem: Rectangle {
            id: tooltipBackground
            color: "transparent"
            radius: 6

            width: tooltipContent.width + 10
            height: tooltipContent.height + 10

            MouseArea {
                id: tooltipMouseArea
                anchors.fill: parent
                hoverEnabled: true

                onEntered: {
                    hideTimer.stop();
                    tooltipRoot.isHovered = true;
                }

                onExited: {
                    tooltipRoot.isHovered = false;
                    hideTimer.restart();
                }
            }

            ColumnLayout {
                id: tooltipContent
                Layout.fillWidth: true

                anchors.centerIn: parent
                spacing: 10

                WindowListHeader {
                    id: windowListHeader
                }

                Rectangle {
                    id: separator
                    Layout.fillWidth: true
                    Layout.leftMargin: 4
                    Layout.rightMargin: 4
                    height: 1
                    color: Qt.rgba(Kirigami.Theme.textColor.r,
                        Kirigami.Theme.textColor.g,
                        Kirigami.Theme.textColor.b, 0.2)
                }

                // Empty state message
                Item {
                    id: emptyState
                    Layout.fillWidth: true
                    height: emptyStateLabel.height + 10
                    visible: false

                    Label {
                        id: emptyStateLabel
                        anchors.centerIn: parent
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        color: Kirigami.Theme.disabledTextColor
                        text: "No windows on this desktop"
                        font.italic: true
                        font.bold: true
                    }
                }

                ListView {
                    id: windowListView
                    clip: false
                    Layout.fillWidth: true
                    Layout.leftMargin: 4
                    Layout.rightMargin: 4
                    Layout.preferredHeight: contentHeight
                    visible: count > 0
                    spacing: 6
                    interactive: false
                    model: ListModel {
                        id: windowsModel
                    }

                    delegate: WindowListItem {
                        width: windowListView.width

                        onDragStarted: {
                        }
                        onDragFinished: {
                            checkHide();
                        }
                    }
                }
            }
        }

        onVisibleChanged: {
            if (!visible) {
                cleanup();
            }
        }
    }

    Timer {
        id: hideTimer
        interval: 50
        running: false

        onTriggered: {
            tooltipRoot.isHovered = false;
            checkHide();
        }
    }

    function checkHide(force = false) {
        if (dragOverlay.visible) {
            hideTimer.restart();
            return;
        }
        if (!tooltipRoot.isHovered && tooltipRoot.sourceButton) {
            if (force || (!tooltipRoot.sourceButton.mouseArea.containsMouse && !tooltipMouseArea.containsMouse)) {
                hide();
            }
        }
    }

    function cleanup() {
        windowListHeader.pulseAnimation.stop();
        windowsModel.clear();
    }

    function updateContent() {
        windowListHeader.name = sourceButton.name || `Desktop ${sourceButton.number + 1}`;
        windowListHeader.pulseAnimation.running = sourceButton.isCurrent;

        const activityId = backend.getCurrentActivityId();
        const activityName = backend.getActivityName(activityId);
        const windows = Common.TaskManager.getWindowsForDesktop(sourceButton.uuid, activityId);

        if (windows.length > 0) {
            windowListHeader.windowCount = `${windows.length} window${windows.length > 1 ? 's' : ''}`;
            emptyState.visible = false;
            windowListView.visible = true;

            windowsModel.clear();
            for (const window of windows) {
                const iconName = backend.getIconFromDesktopFile(window.appId);

                windowsModel.append({
                    "appName": window.appName,
                    "iconName": iconName,
                    "isActive": window.isActive,
                    "genericName": window.genericName,
                    "isDemandingAttention": window.isDemandingAttention,
                    "winId": window.winId,
                    "skipTaskbar": window.skipTaskBar,
                    "skipPager": window.skipPager,
                    "desktopId": sourceButton.uuid,
                    "activityId": window.activityId,
                    "activityName": activityName,
                });
            }
        } else {
            windowListHeader.windowCount = "Empty";
            emptyState.visible = true;
            windowListView.visible = false;
        }
    }

    function hide() {
        tooltipRoot.isHovered = false;
        tooltip.visible = false;
    }

    function show() {
        hideTimer.stop(); // Stop hiding if it's already running
        cleanup();

        tooltip.visualParent = sourceButton;
        tooltip.location = plasmoid.location;

        windowListHeader.desktopIndicator.color = systemPalette.highlight;
        if (!sourceButton.isCurrent) {
            windowListHeader.desktopIndicator.color = Kirigami.Theme.disabledTextColor
        }

        Qt.callLater(() => updateContent());
        Qt.callLater(() => tooltip.visible = true);
    }
}
