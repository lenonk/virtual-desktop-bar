import QtQuick
import QtQuick.Controls
import org.kde.plasma.core as PlasmaCore

TextField {
    id: textField

    implicitWidth: Math.min(300, Math.max(30, hiddenTextInput.contentWidth + 16))
    horizontalAlignment: TextInput.AlignHCenter

    color: PlasmaCore.Theme.textColor
    placeholderTextColor: PlasmaCore.Theme.disabledTextColor

    background: Rectangle {
        color: PlasmaCore.Theme.backgroundColor
        border.color: textField.activeFocus ? PlasmaCore.Theme.highlightColor : PlasmaCore.Theme.disabledTextColor
        border.width: 1
        radius: 3
    }

    TextInput {
        id: hiddenTextInput
        visible: false
        text: textField.text
    }
}