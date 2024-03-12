import QtQuick
import QtQuick.Controls

TextField {
    id: textField
    implicitWidth: Math.min(300, Math.max(30, hiddenTextInput.contentWidth + 16))
    horizontalAlignment: TextInput.AlignHCenter

    TextInput {
        id: hiddenTextInput
        visible: false
        text: textField.text
    }
}
