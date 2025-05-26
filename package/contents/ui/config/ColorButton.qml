import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import org.kde.kirigami as Kirigami

Button {
    id: button

    enabled: false
    implicitWidth: Kirigami.Units.iconSizes.medium
    implicitHeight: Kirigami.Units.iconSizes.smallMedium
    opacity: enabled ? 1 : 0.2

    property var colorAcceptedCallback
    property color color: Kirigami.Theme.textColor // Default color

    // Background to mimic the color button style
    background: Rectangle {
        id: rectangle
        radius: Kirigami.Units.smallSpacing
        border.width: 1
        color: button.color
        border.color: Kirigami.Theme.textColor
    }

    ColorDialog {
        id: dialog
        title: i18n("Choose a Color")
        options: ColorDialog.ShowAlphaChannel
        onAccepted: {
            button.color = selectedColor;
            if (typeof colorAcceptedCallback === "function") {
                colorAcceptedCallback(selectedColor);
            }
        }
    }

    onClicked: dialog.open()

    // Sync dialog color with button color
    Component.onCompleted: dialog.selectedColor = color
}
