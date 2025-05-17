import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore

Item {
    id: root
    readonly property string objectType: "AddDesktopButton"

    Layout.fillWidth: PlasmaCore.Types.Vertical
    Layout.fillHeight: !PlasmaCore.Types.Vertical
    Layout.preferredWidth: PlasmaCore.Types.Vertical ? parent.width : label.width
    Layout.preferredHeight: !PlasmaCore.Types.Vertical ? parent.height : label.height
    Layout.alignment: PlasmaCore.Types.Vertical ? Qt.AlignHCenter : Qt.AlignVCenter
    visible: config.AddDesktopButtonShow && !config.DynamicDesktopsEnable

    Label {
        id: label

        anchors {
            top: parent.top
            left: parent.left
            topMargin: PlasmaCore.Types.Vertical ?
                implicitHeight / -15 :
                (parent.height - height) / 2 - 1
            leftMargin: PlasmaCore.Types.Vertical ?
                (parent.width - width) / 2 :
                implicitWidth / 2.5
        }

        opacity: 1.0
        color: config.DesktopLabelsCustomColor || PlasmaCore.Theme.textColor

        text: "+"
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

        onEntered: container.lastHoveredButton = root
        onClicked: {
            // TODO: Delete when Backend.addDesktop() works
            console.log("Add desktop button clicked")
            //Backend.addDesktop()
        }
    }
}
