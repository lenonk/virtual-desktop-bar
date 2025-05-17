import QtQuick
import QtQuick.Controls
import org.kde.plasma.core as PlasmaCore

import "common" as UICommon

Popup {
    id: root

    x: 0
    y: 0
    width: textField.implicitWidth + 2 * padding
    height: textField.implicitHeight + 2 * padding
    padding: 8

    modal: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    property Item desktopButton: null

    background: Rectangle {
        color: PlasmaCore.Theme.backgroundColor
        border.color: PlasmaCore.Theme.textColor
        border.width: 1
        radius: 3
    }

    UICommon.GrowingTextField {
        id: textField
        anchors.centerIn: parent

        onAccepted: {
            if (text.length > 0) {
                // TODO: Delete when Backend.renameDesktop() works
                console.log("Rename desktop requested:", desktopButton.number, "new name:", text);
                //Backend.renameDesktop(desktopButton.number, text);
            }
            root.close();
        }

        Keys.onEscapePressed: root.close()
    }

    function show(button) {
        if (!button) {
            return;
        }

        desktopButton = button;
        textField.text = button.name;
        textField.selectAll();

        var pos = button.mapToGlobal(0, 0);
        x = pos.x + (button.width - width) / 2;
        y = pos.y + (button.height - height) / 2;

        open();
        textField.forceActiveFocus();
    }

    onOpened: textField.forceActiveFocus()
    onClosed: {
        textField.text = "";
        desktopButton = null;
    }
}
