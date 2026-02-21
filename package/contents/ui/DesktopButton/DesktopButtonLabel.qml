import QtQuick
import QtQuick.Controls
import org.kde.kirigami as Kirigami

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

    font.family: config.LabelFont || Kirigami.Theme.defaultFont.family
    font.pixelSize: config.LabelFontSize || Kirigami.Theme.defaultFont.pixelSize
    font.bold: isCurrent && config.LabelBoldCurrent
}
