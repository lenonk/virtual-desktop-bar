import QtQuick
import QtQuick.Controls
import org.kde.kirigami as Kirigami

TextField {
    id: textField

    implicitWidth: Math.min(300, Math.max(30, hiddenTextInput.contentWidth + 16))
    horizontalAlignment: TextInput.AlignHCenter

    color: Kirigami.Theme.textColor
    placeholderTextColor: Kirigami.Theme.disabledTextColor

    background: Rectangle {
        color: Kirigami.Theme.backgroundColor
        border.color: textField.activeFocus ? Kirigami.Theme.highlightColor : Kirigami.Theme.disabledTextColor
        border.width: 1
        radius: 3
    }

    TextInput {
        id: hiddenTextInput
        visible: false
        text: textField.text
    }
}
