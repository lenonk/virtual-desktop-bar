import QtQuick
import QtQuick.Controls
import org.kde.plasma.core as PlasmaCore

Text {
    property QtObject config: plasmoid.configuration

    // readonly property int tooltipWaitDuration: 800
    // readonly property int animationWidthDuration: 100
    readonly property int animationColorDuration: 300
    readonly property int animationOpacityDuration: 300

    anchors.centerIn: parent

    Behavior on color {
        enabled: config.AnimationsEnable
        animation: ColorAnimation {
            duration: animationColorDuration
        }
    }

    Behavior on opacity {
        enabled: config.AnimationsEnable
        animation: NumberAnimation {
            duration: animationOpacityDuration
        }
    }

    font.family: config.LabelFont || PlasmaCore.Theme.defaultFont.family
    font.pixelSize: config.LabelFontSize || PlasmaCore.Theme.defaultFont.pixelSize
    font.bold: isCurrent && config.LabelBoldCurrent
}