#!/usr/bin/env python3
import configparser
import json
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path

HOME = Path.home()
ROOT = HOME / ".config/quickshell/dotarch"
STATE = ROOT / "state/cursor-font.json"
ENV = HOME / ".config/hypr/modules/env.lua"
AUTOSTART = HOME / ".config/hypr/modules/autostart.lua"
GTK_FILES = [
    HOME / ".config/gtk-3.0/settings.ini",
    HOME / ".config/gtk-4.0/settings.ini",
]
QT_FILE = HOME / ".config/qt6ct/qt6ct.conf"


def atomic_write(path, content):
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp = tempfile.mkstemp(dir=path.parent, prefix=path.name + ".")
    try:
        with os.fdopen(fd, "w") as f:
            f.write(content)
        os.replace(tmp, path)
    except Exception:
        try:
            os.unlink(tmp)
        except OSError:
            pass
        raise


def read_ini(path):
    cfg = configparser.ConfigParser(interpolation=None)
    cfg.optionxform = str
    if path.exists():
        cfg.read(path)
    return cfg


def ini_text(cfg):
    from io import StringIO
    out = StringIO()
    cfg.write(out)
    return out.getvalue()


def cursor_themes():
    found = set()
    for base in (HOME / ".local/share/icons", Path("/usr/share/icons")):
        if not base.exists():
            continue
        for item in base.iterdir():
            if item.is_dir() and (item / "cursors").is_dir():
                found.add(item.name)
    return sorted(found)


def defaults():
    gtk = read_ini(GTK_FILES[0])
    qt = read_ini(QT_FILE)

    def get(section, key, fallback):
        return gtk.get(section, key, fallback=fallback)

    def qtfont(key, fallback_family, fallback_size):
        raw = qt.get("Fonts", key, fallback="")
        if raw:
            parts = raw.strip('"').split(",")
            try:
                return parts[0], int(parts[1])
            except (ValueError, IndexError):
                pass
        return fallback_family, fallback_size

    qtf, qts = qtfont("general", "Inter SemiBold", 11)
    qmf, qms = qtfont("fixed", "JetBrainsMono Nerd Font", 11)

    return {
        "cursor_theme": get("Settings", "gtk-cursor-theme-name", "macOS"),
        "cursor_size": int(get("Settings", "gtk-cursor-theme-size", "36")),
        "gtk_font": get("Settings", "gtk-font-name", "Pomodoro 11").rsplit(" ", 1)[0],
        "gtk_size": int(get("Settings", "gtk-font-name", "Pomodoro 11").rsplit(" ", 1)[-1]),
        "qt_font": qtf,
        "qt_size": qts,
        "qt_fixed_font": qmf,
        "qt_fixed_size": qms,
        "cursor_themes": cursor_themes(),
    }


def qfont(family, size):
    return f'"{family},{size},-1,5,400,0,0,0,0,0,0,0,0,0,0,1,Regular,0,0"'


def apply_live(theme, size):
    subprocess.run(["hyprctl", "setcursor", theme, str(size)],
                   check=True, capture_output=True, text=True)
    subprocess.run(
        ["gsettings", "set", "org.gnome.desktop.interface", "cursor-theme", theme],
        check=True, capture_output=True, text=True
    )
    subprocess.run(
        ["gsettings", "set", "org.gnome.desktop.interface", "cursor-size", str(size)],
        check=False, capture_output=True, text=True
    )


def apply(data):
    theme = str(data["cursor_theme"]).strip()
    if theme not in cursor_themes():
        raise ValueError("That cursor theme is not installed or has no cursor assets.")

    def family(key):
        value = str(data[key]).strip()
        if not value or "\n" in value:
            raise ValueError("Font family cannot be empty.")
        return value

    def size(key):
        value = int(data[key])
        if not 6 <= value <= 48:
            raise ValueError("Font and cursor sizes must be between 6 and 48.")
        return value

    values = {
        "cursor_theme": theme,
        "cursor_size": size("cursor_size"),
        "gtk_font": family("gtk_font"),
        "gtk_size": size("gtk_size"),
        "qt_font": family("qt_font"),
        "qt_size": size("qt_size"),
        "qt_fixed_font": family("qt_fixed_font"),
        "qt_fixed_size": size("qt_fixed_size"),
    }

    for path in GTK_FILES:
        cfg = read_ini(path)
        if not cfg.has_section("Settings"):
            cfg.add_section("Settings")
        cfg.set("Settings", "gtk-cursor-theme-name", theme)
        cfg.set("Settings", "gtk-cursor-theme-size", str(values["cursor_size"]))
        cfg.set("Settings", "gtk-font-name",
                f'{values["gtk_font"]} {values["gtk_size"]}')
        atomic_write(path, ini_text(cfg))

    qt = read_ini(QT_FILE)
    if not qt.has_section("Fonts"):
        qt.add_section("Fonts")
    qt.set("Fonts", "general", qfont(values["qt_font"], values["qt_size"]))
    qt.set("Fonts", "fixed", qfont(values["qt_fixed_font"], values["qt_fixed_size"]))
    atomic_write(QT_FILE, ini_text(qt))

    if ENV.exists():
        env = ENV.read_text()
        env = re.sub(r'hl\.env\("XCURSOR_THEME",\s*"[^"]*"\)',
                     f'hl.env("XCURSOR_THEME", "{theme}")', env)
        env = re.sub(r'hl\.env\("XCURSOR_SIZE",\s*"[^"]*"\)',
                     f'hl.env("XCURSOR_SIZE", "{values["cursor_size"]}")', env)
        env = re.sub(r'hl\.env\("HYPRCURSOR_SIZE",\s*"[^"]*"\)',
                     f'hl.env("HYPRCURSOR_SIZE", "{values["cursor_size"]}")', env)
        atomic_write(ENV, env)

    if AUTOSTART.exists():
        startup = AUTOSTART.read_text()
        startup = re.sub(
            r'^\s*-- Apply macOS cursor theme\s*\n'
            r'\s*hl\.exec_cmd\("hyprctl setcursor [^"]+"\)\s*\n'
            r'\s*hl\.exec_cmd\("gsettings set org\.gnome\.desktop\.interface cursor-theme [^"]+"\)',
            '    -- Restore the selected cursor theme and size\n'
            '    hl.exec_cmd("python3 ~/.config/quickshell/dotarch/scripts/cursor-font-settings.py cursor-startup")',
            startup, flags=re.M
        )
        atomic_write(AUTOSTART, startup)

    atomic_write(STATE, json.dumps(values, indent=2) + "\n")
    apply_live(theme, values["cursor_size"])


def main():
    if len(sys.argv) == 2 and sys.argv[1] == "get":
        data = defaults()
        if STATE.exists():
            try:
                saved = json.loads(STATE.read_text())
                data.update({k: v for k, v in saved.items() if k != "cursor_themes"})
            except Exception:
                pass
        print(json.dumps(data))
        return

    if len(sys.argv) == 2 and sys.argv[1] == "cursor-startup":
        data = json.loads(STATE.read_text()) if STATE.exists() else defaults()
        apply_live(data["cursor_theme"], int(data["cursor_size"]))
        return

    if len(sys.argv) == 10 and sys.argv[1] == "apply":
        keys = ["cursor_theme", "cursor_size", "gtk_font", "gtk_size",
                "qt_font", "qt_size", "qt_fixed_font", "qt_fixed_size"]
        data = dict(zip(keys, sys.argv[2:]))
        apply(data)
        print("Cursor and font settings applied.")
        return

    raise RuntimeError("Usage: get | cursor-startup | apply THEME SIZE GTK_FONT GTK_SIZE QT_FONT QT_SIZE QT_FIXED_FONT QT_FIXED_SIZE")


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(str(e), file=sys.stderr)
        sys.exit(1)
