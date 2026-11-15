#!/usr/bin/env python3
import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path.home() / ".config/quickshell/dotarch"
HYPR = Path.home() / ".config/hypr"
STATE = ROOT / "state/animations.json"
MODULE = HYPR / "modules/desktop-animations.lua"
MAIN = HYPR / "hyprland.lua"

DEFAULTS = {
    "global_enabled": True,
    "global_speed": 100,
    "border_enabled": True,
    "border_speed": 54,
    "windows_enabled": True,
    "windows_speed": 48,
    "windows_in_speed": 41,
    "windows_out_speed": 15,
    "fade_enabled": True,
    "fade_in_speed": 17,
    "fade_out_speed": 15,
    "fade_speed": 30,
    "layers_enabled": True,
    "layers_speed": 38,
    "layers_in_speed": 40,
    "layers_out_speed": 15,
    "fade_layers_in_speed": 18,
    "fade_layers_out_speed": 14,
    "workspaces_enabled": True,
    "workspaces_speed": 40,
    "workspace_curve": "easeInOutCubic",
    "zoom_enabled": True,
    "zoom_speed": 70,
}

SPEED_KEYS = {
    "global_speed", "border_speed", "windows_speed",
    "windows_in_speed", "windows_out_speed",
    "fade_in_speed", "fade_out_speed", "fade_speed",
    "layers_speed", "layers_in_speed", "layers_out_speed",
    "fade_layers_in_speed", "fade_layers_out_speed",
    "workspaces_speed", "zoom_speed",
}

BOOL_KEYS = {
    "global_enabled", "border_enabled", "windows_enabled",
    "fade_enabled", "layers_enabled", "workspaces_enabled",
    "zoom_enabled",
}

CURVES = {
    "easeInOutCubic", "easeOutQuint", "linear", "quick"
}

def atomic_write(path, content):
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, temp = tempfile.mkstemp(prefix=path.name, dir=path.parent)
    try:
        with os.fdopen(fd, "w") as file:
            file.write(content)
        os.replace(temp, path)
    finally:
        if os.path.exists(temp):
            os.unlink(temp)

def load():
    if not STATE.exists():
        return DEFAULTS.copy()
    try:
        data = json.loads(STATE.read_text())
        result = DEFAULTS.copy()
        result.update({k: v for k, v in data.items() if k in DEFAULTS})
        return result
    except Exception:
        return DEFAULTS.copy()

def lua(value):
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, str):
        return json.dumps(value)
    return str(round(float(value), 2))

def animation(leaf, enabled, speed, curve=None, spring=None, style=None):
    parts = [
        f'leaf = {lua(leaf)}',
        f'enabled = {lua(enabled)}',
        f'speed = {lua(speed)}',
    ]
    if curve:
        parts.append(f'bezier = {lua(curve)}')
    if spring:
        parts.append(f'spring = {lua(spring)}')
    if style:
        parts.append(f'style = {lua(style)}')
    return "hl.animation({ " + ", ".join(parts) + " })"

def commands(s):
    global_on = s["global_enabled"]
    curve = s["workspace_curve"]
    calls = [
        animation("global", global_on, s["global_speed"] / 10, curve="default"),
        animation("border", global_on and s["border_enabled"], s["border_speed"] / 10, curve="easeOutQuint"),
        animation("windows", global_on and s["windows_enabled"], s["windows_speed"] / 10, spring="easy"),
        animation("windowsIn", global_on and s["windows_enabled"], s["windows_in_speed"] / 10, spring="easy", style="popin 87%"),
        animation("windowsOut", global_on and s["windows_enabled"], s["windows_out_speed"] / 10, curve="linear", style="popin 87%"),
        animation("fadeIn", global_on and s["fade_enabled"], s["fade_in_speed"] / 10, curve="almostLinear"),
        animation("fadeOut", global_on and s["fade_enabled"], s["fade_out_speed"] / 10, curve="almostLinear"),
        animation("fade", global_on and s["fade_enabled"], s["fade_speed"] / 10, curve="quick"),
        animation("layers", global_on and s["layers_enabled"], s["layers_speed"] / 10, curve="easeOutQuint"),
        animation("layersIn", global_on and s["layers_enabled"], s["layers_in_speed"] / 10, curve="easeOutQuint", style="fade"),
        animation("layersOut", global_on and s["layers_enabled"], s["layers_out_speed"] / 10, curve="linear", style="fade"),
        animation("fadeLayersIn", global_on and s["layers_enabled"], s["fade_layers_in_speed"] / 10, curve="almostLinear"),
        animation("fadeLayersOut", global_on and s["layers_enabled"], s["fade_layers_out_speed"] / 10, curve="almostLinear"),
        animation("workspaces", global_on and s["workspaces_enabled"], s["workspaces_speed"] / 10, curve=curve, style="slide"),
        animation("workspacesIn", global_on and s["workspaces_enabled"], s["workspaces_speed"] / 10, curve=curve, style="slide"),
        animation("workspacesOut", global_on and s["workspaces_enabled"], s["workspaces_speed"] / 10, curve=curve, style="slide"),
        animation("zoomFactor", global_on and s["zoom_enabled"], s["zoom_speed"] / 10, curve="quick"),
    ]
    return calls

def apply(s):
    calls = commands(s)
    code = "; ".join(calls)
    result = subprocess.run(
        ["hyprctl", "eval", code],
        text=True, capture_output=True
    )
    if result.returncode or "error" in result.stdout.lower():
        raise RuntimeError(result.stderr.strip() or result.stdout.strip() or "Hyprland rejected the animation settings")

    module_text = (
        "-- Managed by Dotarch Desktop Settings.\n"
        "-- Animation settings are generated automatically.\n\n"
        + "\n".join(calls) + "\n"
    )
    atomic_write(MODULE, module_text)
    atomic_write(STATE, json.dumps(s, indent=2) + "\n")

    main_text = MAIN.read_text()
    require = 'require("modules.desktop-animations")'
    if require not in main_text:
        anchor = 'require("modules.desktop-settings")'
        if anchor in main_text:
            main_text = main_text.replace(anchor, anchor + "\n" + require, 1)
        else:
            anchor = 'require("modules.windowrules")'
            if anchor in main_text:
                main_text = main_text.replace(anchor, anchor + "\n" + require, 1)
            else:
                main_text = main_text.rstrip() + "\n" + require + "\n"
        atomic_write(MAIN, main_text)

def main():
    if len(sys.argv) == 2 and sys.argv[1] == "get":
        print(json.dumps(load()))
        return

    if len(sys.argv) == 4 and sys.argv[1] == "set":
        key, raw = sys.argv[2], sys.argv[3]
        if key not in DEFAULTS:
            raise RuntimeError("Unknown animation setting")

        s = load()
        if key in BOOL_KEYS:
            if raw not in ("true", "false"):
                raise RuntimeError("Invalid boolean value")
            s[key] = raw == "true"
        elif key in SPEED_KEYS:
            value = int(float(raw))
            s[key] = max(1, min(200, value))
        elif key == "workspace_curve":
            if raw not in CURVES:
                raise RuntimeError("Unsupported animation curve")
            s[key] = raw
        else:
            raise RuntimeError("Unsupported setting")

        apply(s)
        print("OK")
        return

    raise RuntimeError("Usage: animation-settings.py get | set KEY VALUE")

if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        print(str(error), file=sys.stderr)
        sys.exit(1)
