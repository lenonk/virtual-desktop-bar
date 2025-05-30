import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami 2.20 as Kirigami

Item {
    id: dragVisual

    property QtObject config: plasmoid.configuration

    property string appName: ""
    property string iconName: ""
    property string activityId: ""
    property bool isActive: false
    property  bool isDemandingAttention: false
    property string genericName: ""

    height: 40
    width: 200

    Rectangle {
        id: visualRect
        anchors.fill: parent
        radius: 6
        opacity: 0.8
        scale: 0.9

        property color urgentColor:
            config.DesktopIndicatorsCustomColorForDesktopsNeedingAttention ?
                Qt.color(config.DesktopIndicatorsCustomColorForDesktopsNeedingAttention) :
                Qt.color("#e6520c");

        color: model.isActive ? Qt.rgba(systemPalette.highlight.r,
                systemPalette.highlight.g,
                systemPalette.highlight.b, 0.2) :
            model.isDemandingAttention ? Qt.rgba(urgentColor.r,
                    urgentColor.g,
                    urgentColor.b, 0.2) :
                "transparent"
        border.width: (model.isDemandingAttention || model.isActive) ? 1 : 0
        border.color: model.isActive ? systemPalette.highlight : urgentColor

        SystemPalette { id: systemPalette }

        // Drop shadow effect
        Rectangle {
            anchors.fill: parent
            anchors.margins: -2
            radius: parent.radius + 2
            color: "black"
            opacity: 0.3
            z: -1
        }

        RowLayout {
            id: dragLayout
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 8
            }
            spacing: 10

            Item {
                width: 22
                height: 22

                Kirigami.Icon {
                    anchors.fill: parent
                    source: model.iconName
                    visible: true
                }
            }

            Label {
                Layout.fillWidth: true
                text: appName
                elide: Text.ElideRight
                font.weight: model.isActive ? Font.Bold : Font.Normal
                color: Kirigami.Theme.textColor
            }

            Label {
                visible: isActive
                text: "Active"
                color: systemPalette.highlight
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                font.italic: true
            }
            Label {
                visible: isDemandingAttention
                text: {
                    if (backend.getCurrentActivityId() != activityId) {
                        return "Urgent: " + backend.getActivityName(activityId);
                    }

                    return "Urgent"
                }
                color: urgentColor
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                font.italic: true
            }
        }
    }
}