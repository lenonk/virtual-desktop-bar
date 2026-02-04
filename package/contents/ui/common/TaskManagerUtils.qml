pragma Singleton
import QtQuick
import org.kde.taskmanager as TaskManager
import "../common" as Common

QtObject {
    id: root

    property TaskManager.TasksModel tasksModel: TaskManager.TasksModel {
        id: tasksModel
        filterByVirtualDesktop: true
        filterByActivity: true
        filterByScreen: false
        screenGeometry: Qt.rect(0, 0, 0, 0)
    }

    property var activeWindowCache: ({})

    function setScreenFiltering(enabled, geometry) {
        tasksModel.filterByScreen = enabled;
        if (enabled && geometry) {
            tasksModel.screenGeometry = geometry;
        }
    }

    function getActiveWindowName(desktopUuid, activityId) {
        if (!desktopUuid) return "";

        tasksModel.virtualDesktop = desktopUuid;
        tasksModel.activity = activityId || "";

        for (let i = 0; i < tasksModel.count; i++) {
            const taskIndex = tasksModel.index(i, 0);
            const isActive = tasksModel.data(taskIndex, TaskManager.AbstractTasksModel.IsActive);

            if (isActive) {
                const displayName = tasksModel.data(taskIndex, TaskManager.AbstractTasksModel.DisplayRole) || "";
                activeWindowCache[desktopUuid] = displayName;
                return displayName;
            }
        }

        activeWindowCache[desktopUuid] = "";
        return "";
    }

    function hasWindows(desktopUuid, activityId) {
        if (!desktopUuid) return false;

        tasksModel.virtualDesktop = desktopUuid;
        tasksModel.activity = activityId || "";

        return tasksModel.count > 0;
    }

    function getWindowsForDesktop(desktopUuid, activityId) {
        const windows = [];
        if (!desktopUuid) return windows;

        tasksModel.virtualDesktop = desktopUuid;
        tasksModel.activity = activityId || "";

        for (let i = 0; i < tasksModel.count; i++) {
            const taskIndex = tasksModel.index(i, 0);
            const appId = tasksModel.data(taskIndex, TaskManager.AbstractTasksModel.AppId) || "application-x-executable";
            const appName = tasksModel.data(taskIndex, TaskManager.AbstractTasksModel.AppName) || "Unknown Application";
            const isActive = tasksModel.data(taskIndex, TaskManager.AbstractTasksModel.IsActive) || false;
            const genericName = tasksModel.data(taskIndex, TaskManager.AbstractTasksModel.GenericName) || "";
            const isDemandingAttention = tasksModel.data(taskIndex, TaskManager.AbstractTasksModel.IsDemandingAttention) || false;
            const rawWinId = tasksModel.data(taskIndex, TaskManager.AbstractTasksModel.WinIdList) || []
            const rawActivities = tasksModel.data(taskIndex, TaskManager.AbstractTasksModel.Activities || []);
            // const skipTaskBar = taskModel.data(taskIndex, TaskManager.AbstractTasksModel.SkipTaskBar) || false;
            // TODO: TaskManager.AbstractTaskModel.SkipTaskBar is returning window title for some reason.  Remove
            // when viable
            const desktopList = tasksModel.data(taskIndex, TaskManager.AbstractTasksModel.VirtualDesktops);
            const skipPager = tasksModel.data(taskIndex, TaskManager.AbstractTasksModel.SkipPager) || false;
            const skipTaskBar = false;


            if (skipPager || skipTaskBar) {
                continue;
            }

            // This is here to filter out windows with isDemandingAttention set.  I don't want them on every list
            if (!String(desktopList).includes(desktopUuid)) { continue; }

            let str = String(rawWinId);
            let matches = str.match(/{([^}]+)}/);
            const winId = matches && matches[1] ? matches[1] : str;

            str = String(rawActivities);
            matches = str.match(/{([^}]+)}/);
            const taskActivities = matches && matches[1] ? matches[1] : str;

            windows.push({
                appId: appId,
                appName: appName,
                isActive: isActive,
                genericName: genericName,
                isDemandingAttention: isDemandingAttention,
                winId: winId,
                activityId: taskActivities,
                skipTaskBar: skipTaskBar,
                skipPager: skipPager,
            });
        }

        return windows;
    }

    function desktopNeedsAttention(desktopUuid, activityId) {
        if (!desktopUuid) return false;

        tasksModel.virtualDesktop = desktopUuid;
        tasksModel.activity = activityId || "";

        for (let i = 0; i < tasksModel.count; i++) {
            const taskIndex = tasksModel.index(i, 0);
            const isDemandingAttention = tasksModel.data(taskIndex, TaskManager.AbstractTasksModel.IsDemandingAttention);
            let rawActivities = tasksModel.data(taskIndex, TaskManager.AbstractTasksModel.Activities || []);

            // const str = String(rawActivities);
            // const matches = str.match(/{([^}]+)}/);
            // const taskActivities = matches && matches[1] ? matches[1] : str;
            //
            // if (activityId !== taskActivities) { continue; }

            const desktopList = tasksModel.data(taskIndex, TaskManager.AbstractTasksModel.VirtualDesktops);
            if ((desktopList && String(desktopList).includes(desktopUuid)) && isDemandingAttention) {
                return true;
            }
        }

        return false;
    }

    function activateWindow(winId, desktopId, activityId) {
        if (!winId || !desktopId || !activityId) return false;

        tasksModel.virtualDesktop = desktopId;
        tasksModel.activity = activityId || "";

        for (let i = 0; i < tasksModel.count; i++) {
            const taskIndex = tasksModel.index(i, 0);
            let rawWinId = tasksModel.data(taskIndex, TaskManager.AbstractTasksModel.WinIdList) || [];

            const str = String(rawWinId);
            const matches = str.match(/{([^}]+)}/);
            const compWinId = matches && matches[1] ? matches[1] : str;

            if (winId === compWinId) {
                tasksModel.requestActivate(taskIndex);
            }
        }
    }

    // Request entering the window at the given index on the specified virtual desktops.
    // On Wayland, virtual desktop ids are QStrings. On X11, they are uint >0.
    // An empty list has a special meaning: The window is entered on all virtual desktops in the session.
    // On X11, a window can only be on one or all virtual desktops. Therefore, only the first list entry is actually used.
    // On X11, the id 0 has a special meaning: The window is entered on all virtual desktops in the session.
    function requestVirtualDesktops(winId, sourceDesktopId, destDesktopIdList, activityId) {
        if (!winId || !sourceDesktopId || !activityId) return false;

        tasksModel.virtualDesktop = sourceDesktopId;
        tasksModel.activity = activityId || "";

        for (let i = 0; i < tasksModel.count; i++) {
            const taskIndex = tasksModel.index(i, 0);
            let rawWinId = tasksModel.data(taskIndex, TaskManager.AbstractTasksModel.WinIdList) || [];

            const str = String(rawWinId);
            const matches = str.match(/{([^}]+)}/);
            const compWinId = matches && matches[1] ? matches[1] : str;

            if (winId === compWinId) {
                tasksModel.requestVirtualDesktops(taskIndex, destDesktopIdList);
            }
        }
    }
}
