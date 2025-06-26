import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami 2.20 as Kirigami

Item {
    id: dragVisual

    property QtObject config: plasmoid.configuration

    property bool pulse: false
    property string appName: ""
    property string iconName: ""
    property string activityId: ""
    property string desktopId: ""
    property bool isActive: false
    property  bool isDemandingAttention: false
    property string genericName: ""

    height: 40
    width: 200
    clip: true

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

        color: isDemandingAttention ? Qt.rgba(urgentColor.r, urgentColor.g, urgentColor.b, 0.2) :
            Qt.rgba(systemPalette.highlight.r, systemPalette.highlight.g, systemPalette.highlight.b, 0.2);

        border.width: 1
        border.color: isDemandingAttention ? urgentColor : systemPalette.highlight;

        SystemPalette { id: systemPalette }

        SequentialAnimation {
            id: dragVisualPulseAnimation

            running: pulse
            loops: Animation.Infinite

            onStopped: {
                visualRect.opacity = 0.9;
            }

            NumberAnimation {
                target: visualRect
                property: "opacity"
                from: 0.9
                to: 0.5
                duration: 1000
                easing.type: Easing.InOutQuad
            }
            NumberAnimation {
                target: visualRect
                property: "opacity"
                from: 0.5
                to: 0.9
                duration: 1000
                easing.type: Easing.InOutQuad
            }
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