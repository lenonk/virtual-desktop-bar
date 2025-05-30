import QtQuick
import QtQuick.Controls

DropArea {
    id: dropArea
    z: 99

    property bool active: false
    property Item desktopButton: parent

    keys: ["windowTask"]

    // Visual feedback
    Rectangle {
        anchors.fill: parent
        visible: dropArea.active
        color: "transparent"
        border.width: 2
        border.color: "green"
        radius: 4
        opacity: 0.8
    }

    onEntered: (drag) => {
        console.log("Entered drop area for desktop:", desktopButton.uuid);
        if (drag.keys.includes("windowTask")) {
            // active = true;
        }
    }

    onExited: {
        console.log("Exited drop area for desktop:", desktopButton.uuid);
        active = false;
    }

    onDropped: (drop) => {
        console.log("Dropped on desktop:", desktopButton.uuid, "windowId:", drop.getDataAsString("windowId"));
        active = false;

        if (drop.keys.includes("windowTask")) {
            let windowId = drop.getDataAsString("windowId");
            console.log(`Moving window ${windowId} to desktop ${desktopButton.uuid}`);

            // Call your backend function here
            // backend.moveWindowToDesktop(windowId, desktopButton.uuid);

            drop.acceptProposedAction();
        }
    }
}
// DropArea {
//     id: dropArea
//     z: 99
//
//     property bool active: false
//     property int dropIndex: -1
//     property Item desktopButton: parent
//
//     keys: ["windowTask"]
//     Component.onCompleted: {
//         console.log("DropArea created for desktop:", desktopButton ? desktopButton.uuid : "unknown",
//             "size:", width, "x", height, "position:", x, ",", y);
//     }
//
//     onWidthChanged: console.log("DropArea width changed to:", width)
//     onHeightChanged: console.log("DropArea height changed to:", height)
//
//     Item {
//         anchors.fill: parent
//         visible: dropArea.active
//
//         Canvas {
//             id: borderCanvas
//             anchors.fill: parent
//             visible: dropArea.active
//
//             onPaint: {
//                 if (!dropArea.active) { return; }
//                 var ctx = getContext("2d");
//                 ctx.clearRect(0, 0, width, height);
//                 ctx.strokeStyle = "dodgerblue";
//                 ctx.lineWidth = 2;
//                 ctx.setLineDash([3, 2]); // 6px dash, 4px gap
//                 ctx.strokeRect(1, 1, width - 2, height - 2);
//             }
//
//
//             onVisibleChanged: {
//                 requestPaint();
//             }
//
//             Component.onCompleted: {
//                 requestPaint();
//             }
//         }
//     }
//
//     onEntered: (drag) => {
//         console.log("Entered drop area for desktop:", desktopButton.uuid, "with keys:", drag.keys);
//         if (drag.keys.includes("windowTask")) {
//             active = true;
//         }
//     }
//
//     onExited: {
//         console.log("Exited drop area for desktop:", desktopButton.uuid);
//         active = false
//     }
//
//     onDropped: (drop) => {
//         console.log("Dropped on desktop:", desktopButton.uuid, "with mime data:", drop.getDataAsString("windowId"));
//         active = false;
//         if (drop.keys.includes("windowTask")) {
//             console.log(`Moving window ${drop.getDataAsString("windowId")} to desktop ${desktopButton.uuid}`);
//             // backend.moveWindowToDesktop(drop.getDataAsString("windowId"), desktopButton.uuid);
//             drop.acceptProposedAction();
//         } else {
//             console.log("Drop rejected: invalid mime data keys:", drop.keys);
//         }
//     }
// }