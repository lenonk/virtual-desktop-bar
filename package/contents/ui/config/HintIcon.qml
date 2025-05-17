import QtQuick
import QtQuick.Layouts
import org.kde.kirigami 2.20 as Kirigami
import org.kde.plasma.components 3.0 as PlasmaComponents3

PlasmaComponents3.ToolButton {
    id: root

    property string tooltipText

    Layout.maximumWidth: Kirigami.Units.gridUnit * 1.5
    Layout.maximumHeight: Kirigami.Units.gridUnit * 1.5

    display: PlasmaComponents3.AbstractButton.IconOnly
    icon.name: "help-contextual"

    // Use built-in tooltip functionality
    PlasmaComponents3.ToolTip {
        text: root.tooltipText
        visible: root.hovered
        delay: Kirigami.Units.shortDuration
        timeout: -1  // Show until mouse leaves
    }

    // Make the button non-interactive except for tooltip
    enabled: false

    // Ensure cursor changes to help when hovering
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.WhatsThisCursor
        hoverEnabled: true
        onClicked: {} // Consume clicks
    }
}