#!/usr/bin/env python3
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

HYPR = Path.home() / ".config/hypr"
MODULE = HYPR / "modules/desktop-settings.lua"
MAIN = HYPR / "hyprland.lua"

# key: (hypr option, type, section path, scale)
SPECS = {
    "gaps_in": ("general:gaps_in", "int", ("general", "gaps_in"), 1),
    "gaps_out": ("general:gaps_out", "int", ("general", "gaps_out"), 1),
    "border_size": ("general:border_size", "int", ("general", "border_size"), 1),
    "rounding": ("decoration:rounding", "int", ("decoration", "rounding"), 1),
    "rounding_power": ("decoration:rounding_power", "float", ("decoration", "rounding_power"), 1),
    "active_opacity": ("decoration:active_opacity", "float", ("decoration", "active_opacity"), 100),
    "inactive_opacity": ("decoration:inactive_opacity", "float", ("decoration", "inactive_opacity"), 100),
    "blur_enabled": ("decoration:blur:enabled", "bool", ("decoration", "blur", "enabled"), 1),
    "blur_size": ("decoration:blur:size", "int", ("decoration", "blur", "size"), 1),
    "blur_passes": ("decoration:blur:passes", "int", ("decoration", "blur", "passes"), 1),
    "blur_ignore_opacity": ("decoration:blur:ignore_opacity", "bool", ("decoration", "blur", "ignore_opacity"), 1),
    "blur_noise": ("decoration:blur:noise", "float", ("decoration", "blur", "noise"), 100),
    "blur_contrast": ("decoration:blur:contrast", "float", ("decoration", "blur", "contrast"), 100),
    "blur_xray": ("decoration:blur:xray", "bool", ("decoration", "blur", "xray"), 1),
    "blur_new_optimizations": ("decoration:blur:new_optimizations", "bool", ("decoration", "blur", "new_optimizations"), 1),
    "shadow_enabled": ("decoration:shadow:enabled", "bool", ("decoration", "shadow", "enabled"), 1),
    "shadow_range": ("decoration:shadow:range", "int", ("decoration", "shadow", "range"), 1),
    "shadow_render_power": ("decoration:shadow:render_power", "int", ("decoration", "shadow", "render_power"), 1),
    "preserve_split": ("dwindle:preserve_split", "bool", ("dwindle", "preserve_split"), 1),
    "fullscreen_on_one_column": ("scrolling:fullscreen_on_one_column", "bool", ("scrolling", "fullscreen_on_one_column"), 1),
    "resize_on_border": ("general:resize_on_border", "bool", ("general", "resize_on_border"), 1),
    "allow_tearing": ("general:allow_tearing", "bool", ("general", "allow_tearing"), 1),
    "layout": ("general:layout", "str", ("general", "layout"), 1),
}

def run(args):
    return subprocess.run(args, text=True, capture_output=True)

def get_option(option):
    result = run(["hyprctl", "getoption", option, "-j"])
    if result.returncode:
        raise RuntimeError(result.stderr.strip() or f"Could not read {option}")
    data = json.loads(result.stdout)
    for field in ("int", "float", "bool", "str", "css"):
        if field in data:
            value = data[field]
            if field == "css":
                match = re.search(r"-?\d+(?:\.\d+)?", str(value))
                if match:
                    return float(match.group())
            return value
    raise RuntimeError(f"Unexpected response for {option}: {data}")

def read_values():
    values = {}
    for key, (option, kind, _path, scale) in SPECS.items():
        value = get_option(option)
        if kind == "bool":
            values[key] = bool(value)
        elif kind == "str":
            values[key] = str(value)
        else:
            values[key] = round(float(value) * scale, 2)
    return values

def lua(value):
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, str):
        return json.dumps(value)
    if isinstance(value, float):
        return f"{value:.4f}".rstrip("0").rstrip(".")
    return str(value)

def build_tree(values):
    tree = {}
    for key, (_option, kind, path, scale) in SPECS.items():
        value = values[key]
        if kind not in ("bool", "str"):
            value = float(value) / scale
            if kind == "int":
                value = int(round(value))
        node = tree
        for part in path[:-1]:
            node = node.setdefault(part, {})
        node[path[-1]] = value
    return tree

def render_table(value, indent=0):
    pad = " " * indent
    lines = ["{"]
    for key, child in value.items():
        if isinstance(child, dict):
            rendered = render_table(child, indent + 4)
            lines.append(" " * (indent + 4) + f"{key} = {rendered},")
        else:
            lines.append(" " * (indent + 4) + f"{key} = {lua(child)},")
    lines.append(pad + "}")
    return "\n".join(lines)

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

def ensure_loader():
    text = MAIN.read_text()
    line = 'require("modules.desktop-settings")'
    if line in text:
        return
    anchor = 'require("modules.windowrules")'
    if anchor in text:
        text = text.replace(anchor, anchor + "\n" + line, 1)
    else:
        text = text.rstrip() + "\n" + line + "\n"
    backup = MAIN.with_suffix(".lua.desktop-settings-backup")
    if not backup.exists():
        shutil.copy2(MAIN, backup)
    atomic_write(MAIN, text)

def apply(values):
    config = build_tree(values)
    code = "hl.config(" + render_table(config) + ")"
    result = run(["hyprctl", "eval", code])
    if result.returncode or "error" in result.stdout.lower():
        raise RuntimeError(result.stderr.strip() or result.stdout.strip() or "Hyprland rejected the settings")

    module_text = (
        "-- Managed by Dotarch Desktop Settings.\n"
        "-- Changes made here are generated automatically.\n\n"
        "hl.config(" + render_table(config) + ")\n"
    )
    atomic_write(MODULE, module_text)
    ensure_loader()

def main():
    if len(sys.argv) < 2:
        raise RuntimeError("Expected get or set")

    if sys.argv[1] == "get":
        print(json.dumps(read_values()))
        return

    if sys.argv[1] == "set" and len(sys.argv) == 4:
        key, raw = sys.argv[2], sys.argv[3]
        if key not in SPECS:
            raise RuntimeError("Unknown setting")
        values = read_values()
        kind = SPECS[key][1]

        if kind == "bool":
            if raw not in ("true", "false"):
                raise RuntimeError("Invalid boolean")
            value = raw == "true"
        elif kind == "str":
            if key == "layout" and raw not in ("dwindle", "master", "scrolling"):
                raise RuntimeError("Unsupported layout")
            value = raw
        else:
            value = float(raw)
            limits = {
                "gaps_in": (0, 50), "gaps_out": (0, 80),
                "border_size": (0, 10), "rounding": (0, 40),
                "rounding_power": (1, 10), "active_opacity": (10, 100),
                "inactive_opacity": (10, 100), "blur_size": (0, 20),
                "blur_passes": (0, 10), "blur_noise": (0, 30),
                "blur_contrast": (50, 250), "shadow_range": (0, 50),
                "shadow_render_power": (1, 5),
            }
            if key not in limits:
                raise RuntimeError("This setting cannot be adjusted numerically")
            low, high = limits[key]
            value = max(low, min(high, value))
            value = int(value) if kind == "int" else float(value)

        values[key] = value
        apply(values)
        print("OK")
        return

    raise RuntimeError("Invalid command")

if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        print(str(error), file=sys.stderr)
        sys.exit(1)
