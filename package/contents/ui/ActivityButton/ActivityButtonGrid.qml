import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "../common" as Common

Item {
    id: activityButtonGrid
    property QtObject config: plasmoid.configuration

    required property var container
    required property ListModel activityInfoList

    property ActivityButton hoveredButton
    property var activityButtonMap: ({})

    signal activityButtonClicked(int number)
    signal activityButtonHovered(DesktopButton button)
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
            id: activityRepeater
            model: activityButtonGrid.activityInfoList

            delegate: ActivityButton {
                id: activityDelegateButton
                name: model.name
                uuid: model.uuid
                icon: model.icon

                buttonGrid: activityButtonGrid

                visible: true

                Component.onCompleted: {
                    activityButtonGrid.activityButtonMap[uuid] = this;
                    Qt.callLater(updateGridSizes);
                }

                Component.onDestruction: {
                    delete activityButtonGrid.activityButtonMap[uuid];
                    Qt.callLater(updateGridSizes);
                }
            }
        }

        Rectangle {
            id: buttonSeparator

            // configurable if you want later
            property int lineWidth: 2
            property int verticalMargin: 8
            property int horizontalMargin: 8

            Layout.fillHeight: true
            Layout.preferredWidth: lineWidth

            Layout.topMargin: verticalMargin
            Layout.bottomMargin: verticalMargin
            Layout.leftMargin: horizontalMargin
            Layout.rightMargin: horizontalMargin

            radius: lineWidth / 2

            color: config.LabelColor || Kirigami.Theme.textColor
            opacity: 0.3
        }

        // AddActivityButton {
        //     Layout.fillWidth: Common.LayoutProps.isVerticalOrientation
        //     Layout.fillHeight: !Common.LayoutProps.isVerticalOrientation
        //
        //     onAddActivityButtonClicked: {
        //         container.addActivity();
        //     }
        // }

        onImplicitWidthChanged: { activityButtonGrid.implicitWidth = implicitWidth; }
        onImplicitHeightChanged: { activityButtonGrid.implicitHeight = implicitHeight; }
    }

    onActivityButtonClicked: function (uuid) {
        switchToActivity(uuid);
    }

    onActivityButtonHovered: function (button) {
        hoveredButton = button;
    }

    Component.onCompleted: {
        Qt.callLater(updateGridSizes);
    }

    function onButtonImplicitWidthChanged() {
        Qt.callLater(updateGridSizes);
    }

    Connections {
        target: config

        function onButtonCommonSizeChanged() {
            Qt.callLater(updateGridSizes);
        }

        function onValueChanged(key, value) {
            if (key === "ButtonCommonSize" ||
                key === "buttonCommonSize" ||
                key === "DesktopButtonsSetCommonSizeForAll") {
                Qt.callLater(updateGridSizes);
            }
        }
    }

    function updateGridSizes() {
        let maxWidth = 0;

        for (let uuid in activityButtonMap) {
            let button = activityButtonMap[uuid];
            if (button && button.implicitWidth > maxWidth) {
                maxWidth = button.implicitWidth;
            }
        }

        for (let uuid in activityButtonMap) {
            let button = activityButtonMap[uuid];
            if (button) {
                const commonSizeEnabled =
                    (config.ButtonCommonSize !== undefined) ? config.ButtonCommonSize :
                    ((config.buttonCommonSize !== undefined) ? config.buttonCommonSize :
                    ((config.DesktopButtonsSetCommonSizeForAll !== undefined) ? config.DesktopButtonsSetCommonSizeForAll : false));

                button.Layout.preferredWidth = commonSizeEnabled ? maxWidth : button.implicitWidth;
            }
        }
    }
}
