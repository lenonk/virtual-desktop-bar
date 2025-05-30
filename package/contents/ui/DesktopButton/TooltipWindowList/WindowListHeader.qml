import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami 2.20 as Kirigami

RowLayout {
    property alias name: desktopName.text
    property alias windowCount: windowCount.text
    property alias pulseAnimation: pulseAnimation
    property alias desktopIndicator: desktopIndicator

    Layout.minimumWidth: 300
    Layout.maximumWidth: 500
    Layout.leftMargin: 8
    Layout.rightMargin: 8
    spacing: 8

    Rectangle {
        id: desktopIndicator
        width: 12
        height: 12
        radius: 6
        Layout.alignment: Qt.AlignVCenter
        color: systemPalette.highlight

        SequentialAnimation {
            id: pulseAnimation
            running: false
            loops: Animation.Infinite

            NumberAnimation {
                target: desktopIndicator
                property: "opacity"
                from: 1.0
                to: 0.3
                duration: 1000
                easing.type: Easing.InOutQuad
            }
            NumberAnimation {
                target: desktopIndicator
                property: "opacity"
                from: 0.3
                to: 1.0
                duration: 1000
                easing.type: Easing.InOutQuad
            }
        }
    }

    Label {
        id: desktopName
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
        font.bold: true
        font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.1
        color: Kirigami.Theme.textColor
        elide: Text.ElideRight
    }

    Label {
        id: windowCount
        Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
        color: Kirigami.Theme.disabledTextColor
        font.italic: true
    }
}