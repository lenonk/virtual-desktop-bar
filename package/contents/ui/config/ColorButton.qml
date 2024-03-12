import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs

import org.kde.kirigami as Kirigami

Button {
    id: button
    enabled: false
    implicitWidth: Kirigami.Theme.defaultFont.pixelSize * 2.1
    implicitHeight: Kirigami.Theme.defaultFont.pixelSize * 1.67
    opacity: enabled ? 1 : 0.3

    property string color
    property var colorAcceptedCallback

    background: Rectangle {
        radius: 4
        border.width: 1
        color: button.color
        border.color: "gray"
    }

    ColorDialog {
        id: dialog
        title: "Choose a color"
        // #TODO find the right prop on QT6
        // showAlphaChannel: true
        visible: false
        onAccepted: {
            button.color = color;
            colorAcceptedCallback(color);
            dialog.visible = false;
        }
    }

    onClicked: dialog.visible = true

    Component.onCompleted: dialog.color = color
}
