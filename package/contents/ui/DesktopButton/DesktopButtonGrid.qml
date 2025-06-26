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
    property bool commonSizeEnabled: config.DesktopButtonsSetCommonSizeForAll
    property var desktopButtonMap: ({})

    signal desktopButtonClicked(int number)
    signal desktopButtonHovered(DesktopButton button)
    signal buttonImplicitWidthChanged()

    GridLayout {
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
                number: model.id + 1
                name: model.name
                uuid: model.uuid
                isCurrent: model.is_current
                isDummy: model.is_dummy
                buttonGrid: desktopButtonGrid

                Layout.fillWidth: Common.LayoutProps.isVerticalOrientation
                Layout.fillHeight: !Common.LayoutProps.isVerticalOrientation

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

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        hoverEnabled: false
        acceptedButtons: Qt.NoButton

        onWheel: function (wheel) {
            if (!config.MouseWheelSwitchDesktopOnScroll) return;

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

            let invert = config.MouseWheelInvertDesktopSwitchingDirection;
            invert = Common.LayoutProps.isVerticalOrientation ? !invert : invert;
            let wrap = config.MouseWheelWrapDesktopNavigationWhenScrolling;

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
            if (button.isDummy) { continue; } //TODO: Use isDummy property
            if (button && button.number == 1) {
                button.isFirst = true;
                if (desktopInfoList.count <= 3) button.isLast = true;
                else button.isLast = false;
            }
            else if (button && button.number == Math.floor(desktopInfoList.count / 2)) {
                button.isLast = true;
                if (desktopInfoList.count <= 3) button.isFirst = true;
                else button.isFirst = false;
            }
            else if (button) {
                button.isFirst = false;
                button.isLast = false;
            }
        }
    }

    function updateGridSizes() {
        if (config.DesktopButtonsSetCommonSizeForAll) {
            var maxWidth = 0;
            for (var uuid in desktopButtonMap) {
                var button = desktopButtonMap[uuid];
                if (button.isDummy) {
                    button.width = 1;
                    button.implicitWidth = 1;
                    continue;
                }

                if (button && button.implicitWidth > maxWidth) {
                    maxWidth = button.implicitWidth;
                }
            }

            for (var uuid in desktopButtonMap) {
                var button = desktopButtonMap[uuid];
                if (button && !button.isDummy) {
                    button.Layout.preferredWidth = maxWidth;
                }
            }
        } else {
            for (var uuid in desktopButtonMap) {
                var button = desktopButtonMap[uuid];
                if (button) {
                    button.Layout.preferredWidth =
                        button.implicitWidth;
                }
            }
        }
    }
}