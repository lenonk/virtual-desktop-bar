import QtQuick
import QtQuick.Controls
import org.kde.plasma.core as PlasmaCore

PlasmaCore.Dialog {
    property Item target
    property string content

    visualParent: target
    type: PlasmaCore.Dialog.Tooltip
    flags: Qt.WindowDoesNotAcceptFocus
    location: PlasmaCore.Types.LeftEdge

    mainItem: Text {
        text: content
        width: implicitWidth
        height: implicitHeight

        textFormat: Text.RichText
        color: PlasmaCore.Theme.textColor
    }
}
