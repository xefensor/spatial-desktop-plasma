const assert = require('node:assert/strict');
const actions = require('../apps/contents/code/WindowActions.js');
const roles = Object.fromEntries(['ids', 'window', 'parked', 'desktops', 'allDesktops', 'movable', 'closable', 'launcher', 'url'].map(x => [x, x]));
function fixture() {
    const rows = ['first', 'second'].map(id => ({ids:[id], window:true, parked:true, desktops:['old'], movable:true, closable:true}));
    const calls = [];
    const tasks = {get count(){return rows.length;}, makeModelIndex(row){return {row};},
        data(index, role){return rows[index.row]?.[role];},
        requestVirtualDesktops(index, desktops){calls.push(['move', rows[index.row].ids[0], desktops]);},
        requestActivate(index){calls.push(['activate', rows[index.row].ids[0]]); rows.splice(index.row, 1);},
        requestClose(index){calls.push(['close', rows[index.row].ids[0]]); rows.splice(index.row, 1);},
        requestNewInstance(index){calls.push(['launch', rows[index.row].url]);}};
    return {rows, calls, tasks};
}
{
    const f = fixture();
    assert(actions.restore(f.tasks, 'second', 'here', roles));
    assert.deepEqual(f.calls, [['move','second',['here']],['activate','second']]);
    assert.equal(f.rows.length, 1, 'Activation may immediately remove the minimized proxy row');
}
{
    const f = fixture();
    f.rows.reverse(); f.rows.shift();
    assert(actions.close(f.tasks, 'first', roles));
    assert.deepEqual(f.calls, [['close','first']], 'A changed row order cannot close a different window');
    assert.equal(actions.restore(f.tasks, 'first', 'here', roles), false);
    assert.equal(actions.close(f.tasks, 'missing', roles), false);
}
for (const patch of [{desktops:['here']}, {allDesktops:true}]) {
    const f = fixture(); Object.assign(f.rows[0], patch);
    assert(actions.restore(f.tasks, 'first', 'here', roles));
    assert.deepEqual(f.calls, [['activate','first']], 'Already-local and sticky windows keep their assignment');
}
{
    const f = fixture(); f.rows[0].movable = false;
    assert.equal(actions.restore(f.tasks, 'first', 'here', roles), false);
    assert.deepEqual(f.calls, [], 'An immovable foreign window cannot switch the user to another desktop');
    f.rows[0].parked = false;
    assert.equal(actions.close(f.tasks, 'first', roles), false, 'Stale Parked cards cannot operate on an open window');
}
{
    const f = fixture(); f.rows.push({launcher:true,url:'applications:browser.desktop'});
    assert(actions.launch(f.tasks, 'applications:browser.desktop', roles));
    assert.deepEqual(f.calls, [['launch','applications:browser.desktop']], 'Quick launch requests new work, without restoring a parked instance');
    assert.equal(actions.launch(f.tasks, 'missing', roles), false);
}
console.log('Window actions passed: move-before-restore, stale identity, sticky windows, ownership and new-instance launch.');
