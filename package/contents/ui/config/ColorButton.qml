import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import org.kde.kirigami as Kirigami

Button {
    id: button

    enabled: false
    implicitWidth: Kirigami.Units.iconSizes.medium
    implicitHeight: Kirigami.Units.iconSizes.smallMedium
    opacity: enabled ? 1 : 0.2

    property var colorAcceptedCallback
    property color color: Kirigami.Theme.textColor

    background: Rectangle {
        radius: Kirigami.Units.smallSpacing
        border.width: 1
        color: button.color
        border.color: Kirigami.Theme.textColor
    }

    // Create/destroy the dialog to avoid the "white square after cancel" bug
    Loader {
        id: dialogLoader
        active: false

        sourceComponent: ColorDialog {
            id: dlg
            title: i18n("Choose a Color")
            options: ColorDialog.ShowAlphaChannel

            Component.onCompleted: {
                dlg.selectedColor = button.color
            }

            onAccepted: {
                button.color = selectedColor
                if (typeof button.colorAcceptedCallback === "function")
                    button.colorAcceptedCallback(selectedColor)
                dialogLoader.active = false
            }

            onRejected: {
                dialogLoader.active = false
            }
        }
    }

    onClicked: {
        dialogLoader.active = false   // force fresh instance
        dialogLoader.active = true
        dialogLoader.item.selectedColor = button.color
        dialogLoader.item.open()
    }

    onColorChanged: {
        if (dialogLoader.active && dialogLoader.item)
            dialogLoader.item.selectedColor = button.color
    }
}
