#!/usr/bin/env python3
"""Install Spatial Apps and manage only its marked, wide test panel."""
import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import uuid

ROOT = Path(__file__).resolve().parents[1]
PLUGIN = "org.xefensor.spatial.apps"
STATE = Path(os.environ.get("XDG_STATE_HOME", str(Path.home() / ".local/state"))) / "spatial-apps"
RECORD = STATE / "panel.json"


def run(args):
    return subprocess.run([str(arg) for arg in args], text=True, check=True, capture_output=True).stdout.strip()


def plasma(script):
    return run(["qdbus6", "org.kde.plasmashell", "/PlasmaShell", "org.kde.PlasmaShell.evaluateScript", script])


def preflight():
    for command in ["qdbus6", "kpackagetool6"]:
        if not shutil.which(command):
            raise RuntimeError(f"Required command is missing: {command}")
    # Read-only and before installation, panel creation or writing a record.
    plasma("print(panels().length);")


def install():
    data = Path(os.environ.get("XDG_DATA_HOME", str(Path.home() / ".local/share")))
    installed = data / "plasma/plasmoids" / PLUGIN
    print(run(["kpackagetool6", "--type", "Plasma/Applet",
               "--upgrade" if installed.exists() else "--install", ROOT / "apps"]))


def save(record):
    STATE.mkdir(parents=True, exist_ok=True, mode=0o700)
    temporary = RECORD.with_suffix(".tmp")
    temporary.write_text(json.dumps(record, indent=2) + "\n")
    temporary.chmod(0o600)
    temporary.replace(RECORD)


def stop():
    if not RECORD.exists():
        print("No Spatial Apps test panel is recorded.")
        return
    record = json.loads(RECORD.read_text())
    token = record["token"]
    if not isinstance(token, str) or not token:
        raise RuntimeError("Invalid panel record; no panels were changed.")
    plasma("const token=" + json.dumps(token) + ";for(const p of panels()){"
           "p.currentConfigGroup=['SpatialAppsTest'];"
           "if(p.readConfig('token','')===token)p.remove();}")
    # Preserve the token on any failure so cleanup remains retryable.
    RECORD.unlink()
    print("Spatial Apps test panel removed. The widget remains installed.")


def start(width):
    preflight()
    if RECORD.exists():
        raise RuntimeError("A test panel is already recorded. Run this command with 'stop' first.")
    install()
    record = {"token": uuid.uuid4().hex, "width": width}
    save(record)
    script = (
        "const p=new Panel();p.currentConfigGroup=['SpatialAppsTest'];"
        "p.writeConfig('token'," + json.dumps(record["token"]) + ");"
        "p.location='left';p.height=" + str(width) + ";"
        "p.lengthMode='fill';p.hiding='none';p.floating=false;"
        "p.addWidget(" + json.dumps(PLUGIN) + ");print(p.id);"
    )
    try:
        record["panel"] = int(plasma(script).splitlines()[-1])
        save(record)
    except BaseException:
        try:
            stop()
        except Exception as cleanup_error:
            print("Cleanup could not complete; the panel record was retained:", cleanup_error, file=sys.stderr)
        raise
    print(f"Spatial Apps is running in a {width}px left panel.")
    print("Park any app with its minimize button. Click a preview to restore it here.")
    print("Remove this panel: python3 " + str(Path(__file__).resolve()) + " stop")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=["install", "start", "stop"])
    parser.add_argument("--width", type=int, default=280, help="Test panel width in logical pixels (220–520)")
    args = parser.parse_args()
    if not 220 <= args.width <= 520:
        parser.error("--width must be between 220 and 520")
    try:
        if args.command == "install":
            install()
        elif args.command == "start":
            start(args.width)
        else:
            stop()
    except (subprocess.CalledProcessError, RuntimeError, OSError, ValueError) as error:
        detail = getattr(error, "stderr", "") or str(error)
        print(detail.strip(), file=sys.stderr)
        if "bus" in detail.lower() or "socket" in detail.lower():
            print("Run this command from a terminal inside your Plasma desktop session.", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
