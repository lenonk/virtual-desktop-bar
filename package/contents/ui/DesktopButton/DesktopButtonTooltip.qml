import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami 2.20 as Kirigami
import Qt5Compat.GraphicalEffects

import "../common" as Common
import "../common/Utils.js" as Utils

Item {
    id: tooltipRoot

    property QtObject config: plasmoid.configuration

    readonly property int animationDuration: 350

    property var sourceButton: null
    property bool isHovered: false

    SystemPalette { id: systemPalette }

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

                // Desktop name header
                RowLayout {
                    id: desktopHeader
                    Layout.minimumWidth: 300
                    Layout.maximumWidth: 500
                    Layout.leftMargin: 8
                    Layout.rightMargin: 8
                    spacing: 8

                    Rectangle {
                        id: desktopIndicator
                        width: 12
                        height: 12
                        radius: 6
                        Layout.alignment: Qt.AlignVCenter
                        color: systemPalette.highlight

                        // Pulsating animation for current desktop
                        SequentialAnimation {
                            id: pulseAnimation
                            running: false
                            loops: Animation.Infinite

                            NumberAnimation {
                                target: desktopIndicator
                                property: "opacity"
                                from: 1.0
                                to: 0.3
                                duration: 1000
                                easing.type: Easing.InOutQuad
                            }
                            NumberAnimation {
                                target: desktopIndicator
                                property: "opacity"
                                from: 0.3
                                to: 1.0
                                duration: 1000
                                easing.type: Easing.InOutQuad
                            }
                        }
                    }

                    Label {
                        id: desktopName
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        font.bold: true
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.1
                        color: Kirigami.Theme.textColor
                        elide: Text.ElideRight
                    }

                    Label {
                        id: windowCount
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                        color: Kirigami.Theme.disabledTextColor
                        font.italic: true
                    }
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

                // Windows list using ListView for proper stacking
                ListView {
                    id: windowListView
                    Layout.fillWidth: true
                    Layout.leftMargin: 4
                    Layout.rightMargin: 4
                    Layout.preferredHeight: contentHeight
                    visible: count > 0
                    spacing: 6
                    interactive: false
                    model: ListModel { id: windowsModel }

                    delegate: Rectangle {
                        id: windowItemRect
                        width: windowListView.width
                        height: windowItemLayout.height + 16
                        radius: 4

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

                        MouseArea {
                            id: itemMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            propagateComposedEvents: true

                            property color origColor: "transparent"

                            onEntered: {
                                Qt.callLater(function() {
                                    hideTimer.stop();
                                    tooltipRoot.isHovered = true;
                                    origColor = windowItemRect.color;
                                    let hoverColor = model.isDemandingAttention ? urgentColor : systemPalette.highlight;
                                    windowItemRect.color = Qt.rgba(hoverColor.r, hoverColor.g, hoverColor.b, 0.2);
                                    windowItemRect.border.color = hoverColor
                                    windowItemRect.border.width = 1;
                                });
                            }

                            onExited: {
                                tooltipRoot.isHovered = false
                                hideTimer.restart();
                                windowItemRect.color = origColor
                                if (!model.isActive && !model.isDemandingAttention) {
                                    windowItemRect.border.width = 0;
                                }
                            }

                            onClicked: function(mouse) {
                                Common.TaskManager.activateWindow(model.winId, model.desktopId, model.activityId);
                                hide();
                                mouse.accepted = true;
                            }
                        }

                        RowLayout {
                            id: windowItemLayout
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
            checkHideTooltip();
        }
    }

    function checkHideTooltip(force = false) {
        if (!tooltipRoot.isHovered && tooltipRoot.sourceButton) {
            if (force || (!tooltipRoot.sourceButton.mouseArea.containsMouse && !tooltipMouseArea.containsMouse)) {
                hide();
            }
        }
    }

    function cleanup() {
        pulseAnimation.stop();
        windowsModel.clear();
    }

    function updateContent(desktopButton) {
        desktopName.text = desktopButton.name || `Desktop ${desktopButton.number + 1}`;
        pulseAnimation.running = desktopButton.isCurrent;

        const activityId = backend.getCurrentActivityId();
        const activityName = backend.getActivityName(activityId);
        const windows = Common.TaskManager.getWindowsForDesktop(desktopButton.uuid, activityId);

        if (windows.length > 0) {
            windowCount.text = `${windows.length} window${windows.length > 1 ? 's' : ''}`;
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
                    "desktopId": desktopButton.uuid,
                    "activityId": window.activityId,
                    "activityName": activityName,
                });
            }
        } else {
            windowCount.text = "Empty";
            emptyState.visible = true;
            windowListView.visible = false;
        }
    }

    function hide() {
        sourceButton = null;
        tooltipRoot.isHovered = false;
        tooltip.visible = false;
    }

    function show(desktopButton) {
        cleanup();

        tooltipRoot.sourceButton = desktopButton;

        tooltip.visualParent = desktopButton;
        tooltip.location = plasmoid.location;

        desktopIndicator.color = systemPalette.highlight;
        if (!desktopButton.isCurrent) {
            desktopIndicator.color = Kirigami.Theme.disabledTextColor
        }

        Qt.callLater(function() {
            updateContent(desktopButton);
        })

        Qt.callLater(function() {
            tooltip.visible = true;
        });
    }
}
