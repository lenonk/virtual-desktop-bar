import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

import "../common" as UICommon

Kirigami.Icon {
    roundToIconSize: false
    Layout.maximumWidth: Kirigami.Theme.defaultFont.pixelSize * 1.65
    Layout.maximumHeight: Kirigami.Theme.defaultFont.pixelSize * 1.65

    source: "help-contextual"

    property string tooltipText

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
    }

    UICommon.TextTooltip {
        target: parent
        visible: mouseArea.containsMouse
        content: tooltipText
    }
}
