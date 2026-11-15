#!/usr/bin/env python3
import json
import os
import shlex
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path.home() / ".config/quickshell/dotarch"
STATE = ROOT / "state/startup.json"

DEFAULTS = {
    "services": [
        {"id": "awww", "name": "Wallpaper daemon", "description": "Runs the awww wallpaper service.", "enabled": True},
        {"id": "dotarch", "name": "Dotarch shell", "description": "Starts your Quickshell notch and panels.", "enabled": True},
        {"id": "wallpaper", "name": "Restore wallpaper", "description": "Restores your selected wallpaper after login.", "enabled": True},
        {"id": "hypridle", "name": "Hypridle", "description": "Handles idle and automatic screen locking.", "enabled": True},
        {"id": "blueman", "name": "Bluetooth applet", "description": "Provides the Bluetooth tray service.", "enabled": True},
        {"id": "clipboard", "name": "Clipboard history", "description": "Starts your clipboard history watcher.", "enabled": True},
        {"id": "easyeffects", "name": "EasyEffects", "description": "Starts EasyEffects in the background.", "enabled": False}
    ],
    "custom": []
}

def load():
    if not STATE.exists():
        save(DEFAULTS)
    try:
        data = json.loads(STATE.read_text())
        data.setdefault("services", DEFAULTS["services"])
        data.setdefault("custom", [])
        return data
    except Exception:
        return DEFAULTS.copy()

def save(data):
    STATE.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp = tempfile.mkstemp(dir=STATE.parent)
    try:
        with os.fdopen(fd, "w") as f:
            json.dump(data, f, indent=2)
            f.write("\n")
        os.replace(tmp, STATE)
    except Exception:
        try:
            os.unlink(tmp)
        except OSError:
            pass
        raise

def set_enabled(item_id, enabled):
    data = load()
    for item in data["services"] + data["custom"]:
        if item["id"] == item_id:
            item["enabled"] = enabled
            save(data)
            return
    raise ValueError("Unknown startup entry: " + item_id)

def add_custom(name, command):
    name, command = name.strip(), command.strip()
    if not name or not command:
        raise ValueError("Both a name and command are required.")
    data = load()
    data["custom"].append({
        "id": "custom-" + str(os.getpid()) + "-" + str(len(data["custom"])),
        "name": name,
        "description": command,
        "command": command,
        "enabled": True
    })
    save(data)

def remove_custom(item_id):
    data = load()
    data["custom"] = [x for x in data["custom"] if x["id"] != item_id]
    save(data)

def launch():
    data = load()
    home = str(Path.home())
    dotarch = ROOT

    commands = {
        "awww": ["awww-daemon"],
        "dotarch": ["qs", "--no-duplicate", "--path", str(dotarch)],
        "wallpaper": ["bash", "-lc", "sleep 1; " + shlex.quote(str(dotarch / "scripts/theme-system.sh")) + " restore-wallpaper"],
        "hypridle": ["hypridle"],
        "blueman": ["blueman-applet"],
        "clipboard": [home + "/.local/bin/clipboard-history"],
        "easyeffects": ["easyeffects", "--gapplication-service"]
    }

    for item in data["services"]:
        if item.get("enabled") and item["id"] in commands:
            subprocess.Popen(commands[item["id"]])

    for item in data["custom"]:
        if item.get("enabled") and item.get("command"):
            subprocess.Popen(item["command"], shell=True)

    # Restore the selected cursor, if the cursor/font settings backend exists.
    cursor_backend = ROOT / "scripts/cursor-font-settings.py"
    if cursor_backend.exists():
        subprocess.Popen(["python3", str(cursor_backend), "cursor-startup"])

def main():
    args = sys.argv[1:]
    if args == ["get"]:
        print(json.dumps(load()))
    elif args and args[0] == "set" and len(args) == 3:
        set_enabled(args[1], args[2] == "true")
    elif args and args[0] == "add" and len(args) == 3:
        add_custom(args[1], args[2])
    elif args and args[0] == "remove" and len(args) == 2:
        remove_custom(args[1])
    elif args == ["launch"]:
        launch()
    else:
        raise ValueError("Invalid startup-settings command")

if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        print(str(exc), file=sys.stderr)
        sys.exit(1)
