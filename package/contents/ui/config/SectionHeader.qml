import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.kde.kirigami as Kirigami

ColumnLayout {
    spacing: 0

    property string text

    Item {
        height: 10
    }

    Label {
        font.pixelSize: Kirigami.Theme.defaultFont.pixelSize + 4
        text: parent.text
    }

    Item {
        height: 1
    }
}
