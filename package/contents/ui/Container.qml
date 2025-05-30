import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "DesktopButton" as DesktopButton

Item {
    id: root

    // Properties
    property QtObject config: plasmoid.configuration
    property ListModel desktopInfoList: ListModel {}

    signal desktopRenamed(string uuid, string name)
    signal buttonRemoveAnimationCompleted(string uuid)
    signal buttonMiddleClick(DesktopButton.DesktopButton button)
    signal nextDesktop()
    signal previousDesktop()

    implicitWidth: desktopButtonGrid.implicitWidth
    implicitHeight: desktopButtonGrid.implicitHeight

    Backend {
        id: backend
        desktopInfoList: root.desktopInfoList
    }

    DesktopButton.DesktopRenamePopup {
        id: renamePopup
    }

    DesktopButton.DesktopButtonGrid {
        id: desktopButtonGrid

        anchors.centerIn: parent
        container: root
        desktopInfoList: root.desktopInfoList

        Component.onCompleted: {
            root.width = desktopButtonGrid.implicitWidth;
        }
    }

    onImplicitWidthChanged: {
        if (parent && parent.Layout) {
            parent.Layout.preferredWidth = implicitWidth;
        }
    }

    onImplicitHeightChanged: {
        if (parent && parent.Layout) {
            parent.Layout.preferredHeight = implicitHeight;
        }
    }

    onDesktopRenamed: function(uuid, name) {
        backend.setDesktopName(uuid, name);
    }

    onButtonRemoveAnimationCompleted: function(uuid) {
        backend.removeDesktop(uuid);
    }

    onButtonMiddleClick: function(button) {
        button.startRemoveAnimation();
    }

    onNextDesktop: { backend.nextDesktop(); }
    onPreviousDesktop: { backend.previousDesktop(); }

    // Signal handlers
    function addDesktop() {
        backend.createDesktop(desktopInfoList.count, "New Desktop");
    }

    function removeDesktop(last) {
        console.log("removeDesktop() called");
        let desktop = desktopInfoList.get(desktopInfoList.count - 1);
        if (!last) {
            if (!desktopButtonGrid.hoveredButton) {
                console.log("removeDesktop() called with no hovered button!")
                return;
            }

            let doomed = desktopButtonGrid.hoveredButton;
            for (let i = 0; i < desktopInfoList.count; i++) {
                desktop = desktopInfoList.get(i);
                if (desktop.uuid === doomed.uuid) {
                    break;
                }
            }
        }

        let doomed = desktopButtonGrid.desktopButtonMap[desktop.uuid];
        if (doomed) {
            doomed.startRemoveAnimation();
            return;
        }

        // This should never happen, but just in case...
        backend.removeDesktop(desktop.uuid);
    }

    function switchToDesktop(number) {
        backend.setCurrentDesktop(number);
    }

    function renameDesktop() {
        renamePopup.show(desktopButtonGrid.hoveredButton);
    }
}
