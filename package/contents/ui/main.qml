import QtQuick

import org.kde.kquickcontrolsaddons
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

import org.kde.plasma.virtualdesktopbar 1.2

import "applet"

PlasmoidItem {
    id: root

    DesktopRenamePopup { id: renamePopup }
    DesktopButtonTooltip { id: tooltip }

    fullRepresentation: Container {}
    preferredRepresentation: fullRepresentation

    property QtObject config: plasmoid.configuration
    property Item container: fullRepresentationItem

    property bool isTopLocation: plasmoid.location == PlasmaCore.Types.TopEdge
    property bool isVerticalOrientation: plasmoid.formFactor == PlasmaCore.Types.Vertical

    VirtualDesktopBar {
        id: backend

        cfg_EmptyDesktopsRenameAs: config.EmptyDesktopsRenameAs
        cfg_AddingDesktopsExecuteCommand: config.AddingDesktopsExecuteCommand
        cfg_DynamicDesktopsEnable: config.DynamicDesktopsEnable
        cfg_MultipleScreensFilterOccupiedDesktops: config.MultipleScreensFilterOccupiedDesktops
    }

    Connections {
        target: backend

        function onDesktopInfoListSent(desktopInfoList) {
            container.update(desktopInfoList)
        }

         function onRequestRenameCurrentDesktop(container) {
            renamePopup.show(container.currentDesktopButton)
        }
        // onDesktopInfoListSent: container.update(desktopInfoList)
        // onRequestRenameCurrentDesktop: renamePopup.show(container.currentDesktopButton)
    }

    Component.onCompleted: {
        Qt.callLater(function() {
            // initializeContextMenuActions();
            backend.requestDesktopInfoList();
        });
    }

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: "Rename Desktop"
            icon.name: "edit-rename"
            visible: container.lastHoveredButton && container.lastHoveredButton.objectType == "DesktopButton"
            enabled: config.DesktopLabelsStyle != 1
        },
        PlasmaCore.Action {
            text: "Remove Desktop"
            icon.name: "list-remove"
            visible: container.lastHoveredButton && container.lastHoveredButton.objectType == "DesktopButton"
            enabled: !config.DynamicDesktopsEnable
        },
        PlasmaCore.Action {
            text: "Add Desktop"
            icon.name: "list-add"
            enabled: !config.DynamicDesktopsEnable
        },
        PlasmaCore.Action {
            text: "Remove Last Desktop"
            icon.name: "list-remove"
            enabled: !config.DynamicDesktopsEnable
        }
    ]

    function initializeContextMenuActions() {
        // plasmoid.setAction("renameDesktop", "Rename Desktop", "edit-rename");
        // plasmoid.setAction("removeDesktop", "Remove Desktop", "list-remove");
        // plasmoid.setActionSeparator("separator1");
        // plasmoid.setAction("addDesktop", "Add Desktop", "list-add");
        // plasmoid.setAction("removeLastDesktop", "Remove Last Desktop", "list-remove");
        // plasmoid.setActionSeparator("separator2");

        // var renameRemoveDesktopVisible = Qt.binding(function() {
        //     return container.lastHoveredButton && container.lastHoveredButton.objectType == "DesktopButton"
        // });

        // var renameDesktopEnabled = Qt.binding(function() {
        //     return config.DesktopLabelsStyle != 1;
        // });

        // var addRemoveDesktopEnabled = Qt.binding(function() {
        //     return !config.DynamicDesktopsEnable;
        // });

        // plasmoid.action("renameDesktop").visible = renameRemoveDesktopVisible;
        // plasmoid.action("renameDesktop").enabled = renameDesktopEnabled;

        // plasmoid.action("removeDesktop").visible = renameRemoveDesktopVisible;
        // plasmoid.action("removeDesktop").enabled = addRemoveDesktopEnabled;

        // plasmoid.action("separator1").visible = renameRemoveDesktopVisible;
        // plasmoid.action("addDesktop").enabled = addRemoveDesktopEnabled;

        // plasmoid.action("removeLastDesktop").enabled = addRemoveDesktopEnabled;
    }

    function action_renameDesktop() {
        renamePopup.show(container.lastHoveredButton);
    }

    function action_removeDesktop() {
        backend.removeDesktop(container.lastHoveredButton.number);
    }

    function action_addDesktop() {
        backend.addDesktop();
    }

    function action_removeLastDesktop() {
        backend.removeDesktop(container.lastDesktopButton.number);
    }
}
