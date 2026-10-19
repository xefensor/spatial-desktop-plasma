# Spatial Desktop for Plasma

Native Plasma experiments, starting with an independent Plasma 6.8 Apps widget for a wide vertical panel. It implements Quick launch and a scrollable Parked list using real application windows. This repository is independent of the browser demo.

## Start the wide-panel experiment

From a terminal in your Plasma session, at the repository root:

```sh
python3 scripts/panel.py start
```

This installs the widget for your user and creates a marked 280-logical-pixel left panel. Use `--width 320` to choose another width between 220 and 520. Existing panels remain in place, and Krohnkite continues arranging windows around the panel's reserved space. No KWin script, replacement shell, background service or administrator installation is needed.

Minimize any normal app window to park it. The Parked list shows each window separately, across virtual desktops in the current Plasma Activity. Click a preview to move that same window onto the currently viewed desktop and activate it. The close button requests an ordinary window close.

Quick launch stays fixed above the scrollable list. Its initial entries are the default file manager, Konsole and the default browser. It requests a new instance, independently of existing or parked windows; applications may apply their own single-instance policy. Use the widget's normal Plasma configuration dialog to edit launcher addresses and enable or disable previews.

Remove only the test panel:

```sh
python3 scripts/panel.py stop
```

The installer records a random marker before creating the panel. Cleanup checks that marker, leaves unrelated panels alone, and retains its recovery record if Plasma cannot be reached. The record is `~/.local/state/spatial-apps/panel.json`, respecting `XDG_STATE_HOME`. Stopping leaves the widget installed and does not close, move or unpark application windows.

To install the widget without creating a panel:

```sh
python3 scripts/panel.py install
```

Then add **Spatial Apps** through Plasma's widget picker to your own wide panel. The runtime requires Plasma 6.8, its Task Manager and KPipeWire QML modules, Python 3, `kpackagetool6`, and `qdbus6`. This experiment targets Wayland and is intended to run inside `plasmashell`.

## Preview behavior and scope

Previews use the same `TaskManager.ScreencastingRequest` → `PipeWireSourceItem` path as Plasma's Task Manager. Capture is active only for visible cards in a visible widget. Scrolled-out, pooled and hidden cards release their stream. A window excluded from capture is never requested. Missing previews fall back to an application icon and title, preserving restore and close actions. A minimized application may stop repainting; a thumbnail is not a promise of continuous updates or an interactive application surface.

The current Plasma Activity is the first test scope, rather than an implementation of Spatial Workspaces or Project columns. There is no duplicate list of open windows, numbered-window shortcut integration, compact presentation, or Background service section yet. Background services are not classified as parked windows merely because their process remains alive. Existing Plasma launchers, tray and keyboard shortcuts remain usable.

## Develop and check

The widget itself is QML/JavaScript and needs no compilation. Native integration checks additionally require CMake, Ninja, a C++20 compiler, KDE Extra CMake Modules, Qt 6.8+ Core/Gui/Widgets/Qml/Quick/Test development packages, and Plasma/PlasmaQuick development packages.

```sh
bash scripts/check.sh
```

This checks window identity and action ordering, panel recovery, real QML rendering with independent model data, the installed native Task Manager and thumbnail types, and loading the actual applet package in an isolated Plasma containment. All package-test data uses temporary XDG directories. Offscreen checks do not verify live compositor capture, window activation or Krohnkite's response; exercise those in the real desktop after starting the test panel.

The checks create `out/spatial-apps.plasmoid`, an installable ZIP package. `python3 scripts/package.py` packages the widget without compiling or running checks. Build output, screenshots and packages are ignored by Git.

## Upstream references

- [Plasma widget development](https://develop.kde.org/docs/plasma/widget/)
- [Task Manager's Wayland thumbnail](https://github.com/KDE/plasma-desktop/blob/master/applets/taskmanager/qml/PipeWireThumbnail.qml)
- [Task Manager window actions](https://github.com/KDE/plasma-workspace/blob/master/libtaskmanager/tasksmodel.h)

Widget source is licensed GPL-2.0-or-later as declared in its package metadata.

GitHub Actions runs the model, recovery and native Qt/Plasma checks in an openSUSE Tumbleweed container and uploads the installable widget as the `spatial-apps` artifact. The native experiment has no website build or GitHub Pages deployment.
