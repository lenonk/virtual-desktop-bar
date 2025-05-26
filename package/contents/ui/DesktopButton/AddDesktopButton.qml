import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
import "../common" as Common

Rectangle {
    id: root
    property QtObject config: plasmoid.configuration
    property int horizontalPadding: 5
    property int verticalPadding: 5

    signal addDesktopButtonClicked()

    Layout.fillWidth: Common.LayoutProps.isVerticalOrientation
    Layout.fillHeight: !Common.LayoutProps.isVerticalOrientation
    Layout.preferredWidth: label.width + horizontalPadding * 2
    Layout.preferredHeight: label.height + verticalPadding * 2

    Layout.alignment: Qt.AlignCenter

    visible: config.AddDesktopButtonShow && !config.DynamicDesktopsEnable

    color: "transparent"

    Text {
        id: label

        anchors.centerIn: parent

        text: "+"
        opacity: 1.0
        color: config.DesktopLabelsCustomColor || PlasmaCore.Theme.textColor

        font {
            weight: Font.Light
            family: config.DesktopLabelsCustomFont || PlasmaCore.Theme.defaultFont.family
            pixelSize: (config.DesktopLabelsCustomFontSize || PlasmaCore.Theme.defaultFont.pixelSize) * 1.5
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true

        onClicked: {
            addDesktopButtonClicked();
        }
    }
}
