import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "DesktopButton" as DesktopButton
import "common" as Common
import "common/Utils.js" as Utils

Item {
    id: root

    // Properties
    property QtObject config: plasmoid.configuration
    property ListModel desktopInfoList: ListModel {}
    property var lastKnownDesktopStates: ({})  // Track desktop states to prevent loops

    signal desktopRenamed(string uuid, string name)
    signal buttonRemoveAnimationCompleted(string uuid)
    signal buttonMiddleClick(DesktopButton.DesktopButton button)
    signal nextDesktop()
    signal previousDesktop()

    implicitWidth: desktopButtonGrid.implicitWidth
    implicitHeight: desktopButtonGrid.implicitHeight

    Common.Backend {
        id: backend
        desktopInfoList: root.desktopInfoList
    }

    Component.onCompleted: {
        manageDynamicDesktops();
    }

    property bool isRenamingDesktop: renamePopup.visible

    Timer {
        id: checkEmptyTimer
        repeat: false
        onTriggered: {
            checkEmptyDesktops();
        }
    }

    Connections {
        target: Common.TaskManager ? Common.TaskManager.tasksModel : null
        enabled: target !== null

        function onCountChanged() {
            if (config.EmptyDesktopName.length > 0 || config.DynamicDesktops) {
                if (!checkEmptyTimer.running) {
                    checkEmptyTimer.start();
                }
            }
        }
    }

    DesktopButton.DesktopRenamePopup {
        id: renamePopup
    }

    DesktopButton.DesktopButtonGrid {
        id: desktopButtonGrid

        anchors.centerIn: parent
        container: root
        desktopInfoList: root.desktopInfoList
        property bool isRenamingDesktop: root.isRenamingDesktop

        Component.onCompleted: {
            root.width = desktopButtonGrid.implicitWidth;
            updateScreenFiltering();
        }
    }

    // Update screen filtering when config changes
    Connections {
        target: config
        function onFilterByScreenChanged() {
            updateScreenFiltering();
        }
    }

    function updateScreenFiltering() {
        console.log("virtualdesktopbar: updateScreenFiltering:", config.FilterByScreen);
        if (config.FilterByScreen && root.parent && root.parent.Screen) {
            const screen = root.parent.Screen;
            const geometry = Qt.rect(screen.virtualX, screen.virtualY, screen.width, screen.height);
            Common.TaskManager.setScreenFiltering(true, geometry);
        } else {
            Common.TaskManager.setScreenFiltering(false, Qt.rect(0, 0, 0, 0));
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
        var desktopName = config.EmptyDesktopName.length > 0 ? config.EmptyDesktopName : "New Desktop";
        backend.createDesktop(desktopInfoList.count, desktopName);

        if (config.SwitchToNewDesktop) {
            Utils.delay(100, function() {
                    switchToDesktop(desktopInfoList.count);
                },
                root);
        }

        if (config.PromptRenameNew && !config.DynamicDesktops) {
            // Wait for the desktop to be created and button to exist
            Utils.delay(150, function() {
                // Find the button for the newly created desktop (last one in the list)
                if (desktopInfoList.count > 0) {
                    let newDesktop = desktopInfoList.get(desktopInfoList.count - 1);
                    let newButton = desktopButtonGrid.desktopButtonMap[newDesktop.uuid];
                    if (newButton) {
                        renameDesktop(newButton, true);
                    }
                }
            },
            root);
        }
        else if (config.NewDesktopCommand.length > 0) {
            // Only execute this here if we're not renaming.  Otherwise,
            // execute the command when the rename is finished.
            backend.run(config.NewDesktopCommand);
        }
    }

    function removeDesktop(last) {
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

    function renameDesktop(button, isNew) {
        // If no button specified, use the hovered button
        const targetButton = button ? button : desktopButtonGrid.hoveredButton;
        renamePopup.show(targetButton, isNew || false);
    }

    function checkEmptyDesktops() {
        if (config.EmptyDesktopName.length !== 0 && !config.DynamicDesktops) {
            let activityId = backend.getCurrentActivityId();

            for (let i = 0; i < desktopInfoList.count; i++) {
                let desktop = desktopInfoList.get(i);
                let isEmpty = !Common.TaskManager.hasWindows(desktop.uuid, activityId);

                // Create a state key for this desktop
                let stateKey = desktop.uuid + "|" + isEmpty + "|" + desktop.name;

                // Only rename if state has changed and desktop is empty with wrong name
                if (isEmpty && desktop.name !== config.EmptyDesktopName) {
                    let lastState = lastKnownDesktopStates[desktop.uuid];

                    // Only rename if we haven't just renamed this desktop
                    if (lastState !== stateKey) {
                        lastKnownDesktopStates[desktop.uuid] = stateKey;
                        backend.setDesktopName(desktop.uuid, config.EmptyDesktopName);
                    }
                } else {
                    // Update the state even if we don't rename
                    lastKnownDesktopStates[desktop.uuid] = stateKey;
                }
            }
        }

        // Handle dynamic desktops
        manageDynamicDesktops();
    }

    function manageDynamicDesktops() {
        if (!config.DynamicDesktops) return;

        let newDesktopName = config.EmptyDesktopName.length > 0 ? config.EmptyDesktopName : "New Desktop";
        let activityId = backend.getCurrentActivityId();
        let emptyDesktops = [];

        // Count empty and occupied desktops
        for (let i = 0; i < desktopInfoList.count; i++) {
            let desktop = desktopInfoList.get(i);

            if (!Common.TaskManager.hasWindows(desktop.uuid, activityId)) {
                emptyDesktops.push(desktop.uuid);
            }
        }

        if (desktopInfoList.count > 1 && emptyDesktops.length > 1) {
            for (let i = 0; i < emptyDesktops.length - 1; i++) {
                // Too many empty desktops - remove extras (but keep at least 1 desktop total)
                console.log("DynamicDesktops: Removing excess empty desktop");
                backend.removeDesktop(emptyDesktops[i]);
            }
        }

        // Rule: Always have exactly one spare empty desktop
        if (emptyDesktops.length === 0) {
            // No empty desktops - create one
            console.log("DynamicDesktops: Creating new empty desktop");
            backend.createDesktop(desktopInfoList.count, newDesktopName);

            if (config.NewDesktopCommand.length > 0) {
                backend.run(config.NewDesktopCommand);
            }
        }

        for (let i = 1; i < desktopInfoList.count; i++) {
            let desktop = desktopInfoList.get(i);
            console.log("DynamicDesktops: Renaming desktop " + i + " to " + newDesktopName + " (" + i + ")");
            backend.setDesktopName(desktop.uuid, newDesktopName + " (" + i + ")")
        }
    }
}
