import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.plasma.plasmoid

import "common" as UICommon

UICommon.TextTooltip {
    // target: null
    location: plasmoid.location

    onVisibleChanged: {
        if (!visible) {
            Qt.callLater(function() {
                content = "";
            });
        }
    }

    function show(desktopButton) {
        if (renamePopup.visible) {
            return;
        }

        visualParent = desktopButton;

        var list = desktopButton.windowNameList;
        if (list.length === 0) {
            content = "No windows";
        }

        var map = {};
        for (var windowName of list) {
            map[windowName] = (map[windowName] || 0) + 1;
        }

        var windowNames = Object.keys(map);
        var limit = Math.min(windowNames.length, 3);
        content = windowNames.slice(0, limit).map(windowName => {
            var count = map[windowName];
            return (count > 1 ? count + "x " : "") + windowName;
        }).join(", ");

        if (windowNames.length > limit) {
            content += " and more";
        }

        visible = true;
    }
}
