import QtQuick
import QtQuick.Layouts
import org.kde.kirigami 2.20 as Kirigami

ColumnLayout {
    id: root

    property string text

    Layout.fillWidth: true
    spacing: 0

    // Add top margin for spacing between sections
    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: Kirigami.Units.largeSpacing
    }

    // Header text
    Kirigami.Heading {
        Layout.fillWidth: true
        text: root.text
        level: 2
        font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.1
        color: Kirigami.Theme.textColor
        elide: Text.ElideRight
        wrapMode: Text.NoWrap
    }

    // Separator line
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        Layout.topMargin: Kirigami.Units.smallSpacing
        color: Kirigami.Theme.disabledTextColor
        opacity: 0.4
    }
}
