import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import org.kde.kirigami 2.20 as Kirigami
import org.kde.plasma.components 3.0 as PlasmaComponents3

PlasmaComponents3.Button {
    id: root

    property string color
    property var colorAcceptedCallback

    implicitWidth: Kirigami.Units.gridUnit * 2
    implicitHeight: Kirigami.Units.gridUnit * 1.5
    opacity: enabled ? 1.0 : 0.3

    background: Rectangle {
        radius: Kirigami.Units.smallSpacing
        color: root.color
        border {
            width: 1
            color: Kirigami.Theme.disabledTextColor
        }

        // Add visual feedback for hover and press states
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: Kirigami.Theme.highlightColor
            opacity: root.hovered ? 0.1 : (root.pressed ? 0.2 : 0)
        }
    }

    ColorDialog {
        id: colorDialog
        title: i18n("Choose Color")
        currentColor: root.color
        options: ColorDialog.ShowAlphaChannel

        onAccepted: {
            root.color = selectedColor
            if (colorAcceptedCallback) {
                colorAcceptedCallback(selectedColor)
            }
        }
    }

    onClicked: colorDialog.open()

    PlasmaComponents3.ToolTip {
        text: i18n("Click to change color")
        visible: root.hovered
    }

    Component.onCompleted: {
        // Enable the button by default, unlike the original
        enabled = true
    }
}