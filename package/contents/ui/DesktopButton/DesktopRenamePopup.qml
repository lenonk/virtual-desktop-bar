import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore

import "../common" as Common

PlasmaCore.Dialog {
    id: root

    property var callback: function() {}
    property bool isNew: false

    visualParent: null
    location: plasmoid.location
    hideOnWindowDeactivate: true
    flags: Qt.WindowStaysOnTopHint
    type: PlasmaCore.Dialog.PopupMenu

    mainItem: RowLayout {
        width: implicitWidth

        Text {
            Layout.alignment: Qt.AlignVCenter
            color: PlasmaCore.Theme.textColor
            text: "Rename As: "
        }

        Common.GrowingTextField {
            id: desktopNameInput
            implicitHeight: 28
            maximumLength: 20

            onAccepted: {
                callback();
            }

            Keys.onEscapePressed: {
                root.visible = false;
            }
        }
    }

    onVisibleChanged: {
        if (!visible) {
            callback = function() {};
            Qt.callLater(function() {
                visualParent = null;
                desktopNameInput.text = "";
            });
        }
    }

    function show(desktopButton, isNew) {
        if (!desktopButton) {
            console.warn("Cannot show rename popup: no button provided");
            return;
        }

        visualParent = desktopButton;
        isNew = isNew || false;

        desktopNameInput.text = desktopButton.name;

        callback = function() {
            var name = desktopNameInput.text.trim();
            if (name.length > 0) {
                desktopRenamed(desktopButton.uuid, name);
            }

            if (isNew && config.NewDesktopCommand.length > 0) {
                backend.run(config.NewDesktopCommand);
            }

            visible = false;
        };

        visible = true;

        Qt.callLater(function() {
            desktopNameInput.focus = true;
            desktopNameInput.selectAll();
        });
    }
}