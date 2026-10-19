# Spatial Desktop for Plasma

This repository contains native KDE Plasma experiments. Keep it independent of the browser demo repository; do not add website source, GitHub Pages deployment, or the discarded native shell implementation here.

- The first component is `apps/`, the Spatial Apps widget for a wide vertical panel on Plasma 6.8 / Wayland.
- Keep Quick launch separate from parked-window restore actions. Each Parked card represents one existing window, across desktops in the current Plasma Activity. Background services are a separate future feature.
- Use Plasma's Task Manager and KPipeWire interfaces. Preserve window identity when model rows change, move before activating on restore, honor capture exclusions, and release invisible preview streams.
- Runtime code is QML/JavaScript and does not require compilation. `scripts/` contains installation, panel recovery and packaging; `tests/` contains model, recovery and native Qt/Plasma integration checks.
- Run `bash scripts/check.sh` before delivering changes. It produces `out/spatial-apps.plasmoid`. Build output, packages and test screenshots are ignored by Git.
- Offscreen rendering and isolated applet loading do not establish live compositor capture or window activation. Report whether those interactions were exercised in the actual Plasma session.
- Preserve unrelated panels, files and window-manager settings. The test launcher may create and remove only its own marked panel.
- Keep the README and installed package metadata consistent with this repository and its paths.
