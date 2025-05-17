import QtQuick
import QtQuick.Controls
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.plasma.core as PlasmaCore

PlasmaComponents3.ToolTip {
    id: root

    property Item visualParent: null
    property int location: PlasmaCore.Types.BottomEdge
    property alias content: contentLabel.text

    delay: 0
    timeout: -1

    contentItem: Label {
        id: contentLabel
        color: PlasmaCore.Theme.textColor
        font: PlasmaCore.Theme.defaultFont
        wrapMode: Text.WordWrap
        maximumLineCount: 3
        elide: Text.ElideRight
    }

    background: Rectangle {
        color: PlasmaCore.Theme.backgroundColor
        border.color: PlasmaCore.Theme.disabledTextColor
        border.width: 1
        radius: 3
        opacity: 0.9
    }

    onVisualParentChanged: {
        if (visualParent) {
            parent = visualParent;
        }
    }

    onLocationChanged: {
        switch (location) {
            case PlasmaCore.Types.TopEdge:
                // y = parent.height;
                y = root.height;
                break;
            case PlasmaCore.Types.BottomEdge:
                y = -height;
                break;
            case PlasmaCore.Types.LeftEdge:
                // x = parent.width;
                x = root.width;
                break;
            case PlasmaCore.Types.RightEdge:
                x = -width;
                break;
        }

        // x += (parent.width - width) / 2;
        // y += (parent.height - height) / 2;

        x += (root.width - width) / 2;
        y += (root.height - height) / 2;
    }
}
