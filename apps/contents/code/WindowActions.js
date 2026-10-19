// Resolve window identity at the time of the action: proxy rows can change.
function findWindow(tasks, id, roles) {
    if (!id) return null;
    for (let row = 0; row < tasks.count; row++) {
        const index = tasks.makeModelIndex(row);
        const ids = tasks.data(index, roles.ids) || [];
        if (tasks.data(index, roles.window) && tasks.data(index, roles.parked)
                && Array.from(ids).some(value => String(value) === String(id))) return index;
    }
    return null;
}

function restore(tasks, id, desktop, roles) {
    const index = findWindow(tasks, id, roles);
    if (index === null || desktop === undefined || desktop === null || desktop === "") return false;
    const desktops = tasks.data(index, roles.desktops) || [];
    const alreadyHere = tasks.data(index, roles.allDesktops)
        || Array.from(desktops).some(value => String(value) === String(desktop));
    if (!alreadyHere) {
        if (!tasks.data(index, roles.movable)) return false;
        tasks.requestVirtualDesktops(index, [desktop]);
    }
    // Activate restores a minimized window. A separate minimize toggle would
    // remove the proxy row before activation, and could target a different app.
    tasks.requestActivate(index);
    return true;
}

function close(tasks, id, roles) {
    const index = findWindow(tasks, id, roles);
    if (index === null || !tasks.data(index, roles.closable)) return false;
    tasks.requestClose(index);
    return true;
}

function launch(tasks, url, roles) {
    for (let row = 0; row < tasks.count; row++) {
        const index = tasks.makeModelIndex(row);
        if (tasks.data(index, roles.launcher)
                && String(tasks.data(index, roles.url)) === String(url)) {
            tasks.requestNewInstance(index);
            return true;
        }
    }
    return false;
}

if (typeof module !== "undefined") module.exports = {findWindow, restore, close, launch};
