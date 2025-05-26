import QtQuick
import org.kde.plasma.virtualdesktopbar 1.0


VirtualDesktopBar {
    id: backend

    required property ListModel desktopInfoList

    Component.onCompleted: {
        if (backend) {
            console.log("Backend is ready. Requesting desktop info list...");
            initializeDesktopInfoList(backend.requestDesktopInfoList());
        }
    }

    onDesktopCreated: function (desktopId, desktopData) {
        let newDesktop = {
            "id": desktopData.id || 0,
            "uuid": desktopId,
            "name": desktopData.name || "Desktop " + (desktopInfoList.count + 1),
            "is_current": false,
        };

        desktopInfoList.append(newDesktop);

    }

    onDesktopRemoved: function (desktopId) {
        for (let i = 0; i < desktopInfoList.count; i++) {
            const desktop = desktopInfoList.get(i);
            if (desktop.uuid === desktopId) {
                desktopInfoList.remove(i);
                break;
            }
        }
    }

    onDesktopDataChanged: function (desktopId, desktopData) {
        for (let i = 0; i < desktopInfoList.count; i++) {
            const desktop = desktopInfoList.get(i);
            if (desktop.uuid === desktopId) {
                let updatedDesktop = {
                    "id": desktopData.id !== undefined ? desktopData.id : desktop.id,
                    "uuid": desktopId,
                    "name": desktopData.name !== undefined ? desktopData.name : desktop.name,
                    "is_current": desktop.is_current,
                };

                desktopInfoList.set(i, updatedDesktop);
                break;
            }
        }

    }

    onCurrentChanged: function (desktopId) {
        for (let i = 0; i < desktopInfoList.count; i++) {
            desktopInfoList.setProperty(i, "is_current", false);
            const desktop = desktopInfoList.get(i);
            if (desktop.uuid === desktopId) {
                desktopInfoList.setProperty(i, "is_current", true);
            }
        }
    }

    function initializeDesktopInfoList(data) {
        desktopInfoList.clear();

        for (let i = 0; i < data.length; i++) {
            desktopInfoList.append(data[i]);
        }
    }
}