import QtQuick
import QtQuick.Controls
import QtQuick.Window
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami 2.2 as Kirigami

import "common" as Common

PlasmoidItem {
    id: plasmoidRoot

    property QtObject config: plasmoid.configuration
    property Item container: null

    property int location: Plasmoid.location
    property int formFactor: Plasmoid.formFactor
    property bool isTopLocation: location === PlasmaCore.Types.TopEdge
    property bool isVerticalOrientation: formFactor === PlasmaCore.Types.Vertical

    Component.onCompleted: {
        Common.LayoutProps.formFactor = Qt.binding(() => plasmoidRoot.formFactor);
        Common.LayoutProps.location = Qt.binding(() => plasmoidRoot.location);
        Common.LayoutProps.isTopLocation = Qt.binding(() => plasmoidRoot.isTopLocation);
        Common.LayoutProps.isVerticalOrientation = Qt.binding(() => plasmoidRoot.isVerticalOrientation);
    }

    Window {
        id: dragOverlay

        x: Screen.virtualX
        y: Screen.virtualY
        width: Screen.width
        height: Screen.height

        flags:
            Qt.Popup |
            Qt.FramelessWindowHint |
            Qt.WindowStaysOnTopHint |
            Qt.WindowTransparentForInput |
            Qt.BypassWindowManagerHint

        color: "transparent"

        Rectangle {
            id: dragOverlayContent

            anchors.fill: parent
            color: "transparent"
            // border.width: 2
            // border.color: "red"
        }
    }

    preferredRepresentation: fullRepresentation
    fullRepresentation: Loader {
        id: fullLoader
        source: "Container.qml"

        onLoaded: {
            plasmoidRoot.container = item;
            item.parent = plasmoidRoot;
        }
    }

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18n("Rename Desktop")
            icon.name: "edit-rename"
            onTriggered: plasmoidRoot.action_renameDesktop()
        },
        PlasmaCore.Action {
            text: i18n("Remove Desktop")
            icon.name: "list-remove"
            onTriggered: plasmoidRoot.action_removeDesktop()
        },
        PlasmaCore.Action {
            isSeparator: true
        },
        PlasmaCore.Action {
            text: i18n("Add Desktop")
            icon.name: "list-add"
            onTriggered: plasmoidRoot.action_addDesktop()
        },
        PlasmaCore.Action {
            text: i18n("Remove Last Desktop")
            icon.name: "list-remove"
            onTriggered: plasmoidRoot.action_removeLastDesktop()
        },
        PlasmaCore.Action {
            isSeparator: true
        }
    ]

    function action_addDesktop() {
        container.addDesktop();
    }

    function action_removeDesktop() {
        // This function doesn't know which desktop is going to be removed, but container does
        container.removeDesktop(false);
    }

    function action_renameDesktop() {
        container.renameDesktop();
    }

    function action_removeLastDesktop() {
        container.removeDesktop(true);
    }
}
