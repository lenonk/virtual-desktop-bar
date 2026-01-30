import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: windowItemPlaceholder

    property QtObject config: plasmoid.configuration
    property bool isDemandingAttention: false

    radius: 4

    SystemPalette { id: systemPalette }

    property color urgentColor:
        config.IndicatorColorAttention ?
            Qt.color(config.IndicatorColorAttention) :
            Qt.color("#e6520c");

    color: "transparent"

    border.width: 1
    border.color: isDemandingAttention ? urgentColor : systemPalette.highlight

    Behavior on opacity { NumberAnimation { duration: 150 } }
    Behavior on scale { NumberAnimation { duration: 150 } }
}