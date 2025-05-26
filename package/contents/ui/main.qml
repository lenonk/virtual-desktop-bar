import QtQuick
import QtQuick.Controls
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents3

import "common" as Common

PlasmoidItem {
    id: root

    property QtObject config: plasmoid.configuration
    property Item container: null

    property int location: Plasmoid.location
    property int formFactor: Plasmoid.formFactor
    property bool isTopLocation: location === PlasmaCore.Types.TopEdge
    property bool isVerticalOrientation: formFactor === PlasmaCore.Types.Vertical

    Component.onCompleted: {
        Common.LayoutProps.formFactor = Qt.binding(() => root.formFactor);
        Common.LayoutProps.location = Qt.binding(() => root.location);
        Common.LayoutProps.isTopLocation = Qt.binding(() => root.isTopLocation);
        Common.LayoutProps.isVerticalOrientation = Qt.binding(() => root.isVerticalOrientation);
    }

    preferredRepresentation: fullRepresentation
    fullRepresentation: Loader {
        id: fullLoader
        source: "Container.qml"

        onLoaded: {
            root.container = item;
            item.parent = root;
        }
    }

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18n("Rename Desktop")
            icon.name: "edit-rename"
            onTriggered: root.action_renameDesktop()
        },
        PlasmaCore.Action {
            text: i18n("Remove Desktop")
            icon.name: "list-remove"
            onTriggered: root.action_removeDesktop()
        },
        PlasmaCore.Action {
            isSeparator: true
        },
        PlasmaCore.Action {
            text: i18n("Add Desktop")
            icon.name: "list-add"
            onTriggered: root.action_addDesktop()
        },
        PlasmaCore.Action {
            text: i18n("Remove Last Desktop")
            icon.name: "list-remove"
            onTriggered: root.action_removeLastDesktop()
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