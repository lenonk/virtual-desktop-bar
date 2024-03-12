import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami

import "../common" as UICommon

PlasmaCore.Dialog {
    visualParent: null
    location: plasmoid.location

    hideOnWindowDeactivate: true
    flags: Qt.WindowStaysOnTopHint
    type: PlasmaCore.Dialog.PopupMenu

    property var callback

    mainItem: RowLayout {
        width: implicitWidth

        Text {
            Layout.alignment: Qt.AlignVCenter
            color: Kirigami.Theme.textColor
            text: "Rename as"
        }

        UICommon.GrowingTextField {
            id: desktopNameInput
            implicitHeight: 28
            maximumLength: 20
            onAccepted: function() {
                callback();
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

    function show(desktopButton) {
        visualParent = desktopButton;

        desktopNameInput.text = desktopButton.name;
        desktopNameInput.focus = true;
        desktopNameInput.selectAll();

        callback = function() {
            var name = desktopNameInput.text.trim();
            if (name.length > 0) {
                backend.renameDesktop(desktopButton.number, name);
                visible = false;
            }
        }

        visible = true;
    }
}
