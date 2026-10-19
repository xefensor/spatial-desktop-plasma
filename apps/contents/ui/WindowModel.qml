import QtQuick
import org.kde.taskmanager as TaskManager
import "../code/WindowActions.js" as Actions

Item {
    id: root
    property var launchers: []
    readonly property alias parked: parkedTasks
    readonly property alias currentDesktop: desktops.currentDesktop
    readonly property alias activity: activities.currentActivity
    property var launcherEntries: []
    property bool refreshPending: false
    signal operationFailed(string message)

    readonly property var roles: ({
        ids: TaskManager.AbstractTasksModel.WinIdList,
        window: TaskManager.AbstractTasksModel.IsWindow,
        parked: TaskManager.AbstractTasksModel.IsMinimized,
        desktops: TaskManager.AbstractTasksModel.VirtualDesktops,
        allDesktops: TaskManager.AbstractTasksModel.IsOnAllVirtualDesktops,
        movable: TaskManager.AbstractTasksModel.IsVirtualDesktopsChangeable,
        closable: TaskManager.AbstractTasksModel.IsClosable,
        launcher: TaskManager.AbstractTasksModel.IsLauncher,
        url: TaskManager.AbstractTasksModel.LauncherUrlWithoutIcon
    })

    TaskManager.ActivityInfo { id: activities }
    TaskManager.VirtualDesktopInfo { id: desktops }
    TaskManager.TasksModel {
        id: parkedTasks
        groupMode: TaskManager.TasksModel.GroupDisabled
        sortMode: TaskManager.TasksModel.SortDisabled
        filterNotMinimized: true
        filterByVirtualDesktop: false
        filterByScreen: false
        filterByActivity: true
        activity: activities.currentActivity
    }
    TaskManager.TasksModel {
        id: launcherTasks
        launcherList: root.launchers
        separateLaunchers: true
        hideActivatedLaunchers: false
        groupMode: TaskManager.TasksModel.GroupDisabled
        sortMode: TaskManager.TasksModel.SortManual
        onCountChanged: root.scheduleLaunchers()
        onLauncherListChanged: root.scheduleLaunchers()
    }
    Connections {
        target: launcherTasks
        function onDataChanged() { root.scheduleLaunchers() }
        function onModelReset() { root.scheduleLaunchers() }
    }
    function scheduleLaunchers() {
        if (refreshPending) return
        refreshPending = true
        Qt.callLater(function() { root.refreshPending = false; root.refreshLaunchers() })
    }
    function refreshLaunchers() {
        const entries = []
        for (let row = 0; row < launcherTasks.count; row++) {
            const index = launcherTasks.makeModelIndex(row)
            if (!launcherTasks.data(index, roles.launcher)) continue
            entries.push({
                url: String(launcherTasks.data(index, roles.url)),
                title: String(launcherTasks.data(index, TaskManager.AbstractTasksModel.AppName)
                    || launcherTasks.data(index, Qt.DisplayRole) || qsTr("Application")),
                icon: launcherTasks.data(index, Qt.DecorationRole)
            })
        }
        // Running-state changes must not replace focused launcher buttons.
        const signature = values => JSON.stringify(values.map(value => [value.url, value.title]))
        if (signature(entries) !== signature(launcherEntries)) launcherEntries = entries
    }
    function launch(url) {
        if (!Actions.launch(launcherTasks, url, roles))
            operationFailed(qsTr("This application is no longer available. Check Quick launch in the widget settings."))
    }
    function restore(id) {
        if (!Actions.restore(parkedTasks, id, desktops.currentDesktop, roles))
            operationFailed(qsTr("This window could not be restored onto the current desktop."))
    }
    function closeWindow(id) {
        if (!Actions.close(parkedTasks, id, roles))
            operationFailed(qsTr("This window is no longer available or cannot be closed."))
    }
    Component.onCompleted: scheduleLaunchers()
}
