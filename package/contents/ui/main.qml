import QtQuick
import QtQuick.Controls

import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents3

import "common" as Common
import "."

PlasmoidItem {
    id: root

    DesktopRenamePopup { id: renamePopup }
    DesktopButtonTooltip { id: tooltip }

    property QtObject config: plasmoid.configuration
    property Container container: null

    property int location: Plasmoid.location
    property int formFactor: Plasmoid.formFactor
    property bool isTopLocation: location === PlasmaCore.Types.TopEdge
    property bool isVerticalOrientation: formFactor === PlasmaCore.Types.Vertical

    Component.onCompleted: {
        Common.LayoutProps.formFactor = Qt.binding(() => root.formFactor);
        Common.LayoutProps.location = Qt.binding(() => root.location);
        Common.LayoutProps.isTopLocation = Qt.binding(() => root.location === PlasmaCore.Types.TopEdge);
        Common.LayoutProps.isVerticalOrientation = Qt.binding(() => root.formFactor === PlasmaCore.Types.Vertical);
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
            text: i18n("Add Desktop")
            icon.name: "list-add"
            onTriggered: { action_addDesktop(); }
        },
        PlasmaCore.Action {
            text: i18n("Remove Desktop")
            icon.name: "list-remove"
            onTriggered: { action_removeDesktop(); }
        },
        PlasmaCore.Action {
            text: i18n("Rename Desktop")
            icon.name: "edit-rename"
            onTriggered: { action_renameDesktop(); }
        },
        // TODO: Figure out how to add a separator here
        PlasmaCore.Action {
            text: i18n("Remove Last Desktop")
            icon.name: "list-remove"
            onTriggered: { action_removeLastDesktop(); }
        }
    ]

    // Stub out backend actions temporarily with console logs
    function action_renameDesktop() {
        renamePopup.show(container.lastHoveredButton);
    }

    function action_removeDesktop() {
        console.log("virtualdesktopbar: Remove desktop requested:", container.lastHoveredButton.number);
    }

    function action_addDesktop() {
        console.log("virtualdesktopbar: Add desktop requested");
    }

    function action_removeLastDesktop() {
        console.log("virtualdesktopbar: Remove last desktop requested:", container.lastDesktopButton.number);
    }
}
