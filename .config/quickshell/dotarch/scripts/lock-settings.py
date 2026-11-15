#!/usr/bin/env python3
import json
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path

QYLOCK = Path.home() / ".config/qylock"
THEMES = QYLOCK / "themes"
CONFIG = QYLOCK / "theme"
INSTALLER = QYLOCK / "scripts/install-sddm-themes.py"
SDDM_CONFIG = Path("/etc/sddm.conf.d/theme.conf")
PREFIX = "qylock-"

def theme_sources():
    result = []

    for folder in sorted(THEMES.iterdir(), key=lambda p: p.name.lower()):
        if not folder.is_dir() or folder.name == "clockwork":
            continue
        if (folder / "Main.qml").is_file():
            result.append((folder.name, folder))

    clockwork = THEMES / "clockwork"
    if clockwork.is_dir():
        for folder in sorted(clockwork.iterdir(), key=lambda p: p.name.lower()):
            if folder.is_dir() and (folder / "Main.qml").is_file():
                result.append(("clockwork-" + folder.name, folder))

    return result

def resolve_theme(slug):
    for key, folder in theme_sources():
        if key == slug:
            return folder
    raise ValueError("That Qylock theme is not available: " + slug)

def read_sddm_current():
    if not SDDM_CONFIG.is_file():
        return ""
    in_theme = False
    for line in SDDM_CONFIG.read_text(errors="replace").splitlines():
        stripped = line.strip()
        if stripped.startswith("[") and stripped.endswith("]"):
            in_theme = stripped.lower() == "[theme]"
        elif in_theme and re.match(r"^Current\s*=", stripped, re.I):
            return stripped.split("=", 1)[1].strip()
    return ""

def active_qylock_theme():
    current = read_sddm_current()
    return current[len(PREFIX):] if current.startswith(PREFIX) else ""

def preview_path(slug, folder):
    generated = QYLOCK / "previews" / f"{slug}.jpg"
    if generated.is_file():
        return generated

    for pattern in ("*.png", "*.jpg", "*.jpeg", "*.webp"):
        found = sorted(folder.glob(pattern))
        if found:
            return found[0]
    return None

def get():
    selected = CONFIG.read_text().strip() if CONFIG.exists() else "nier-automata"
    themes = []

    for slug, folder in theme_sources():
        conf = folder / "theme.conf"
        values = {}
        if conf.is_file():
            for line in conf.read_text(errors="replace").splitlines():
                line = line.strip()
                if "=" in line and not line.startswith("#"):
                    key, value = line.split("=", 1)
                    values[key.strip().lower()] = value.strip()

        preview = preview_path(slug, folder)
        name = (
            values.get("name")
            or values.get("title")
            or slug.replace("-", " ").replace("_", " ").title()
        )

        themes.append({
            "key": slug,
            "name": name,
            "preview": str(preview) if preview else "",
            "animated": any(folder.glob("*.mp4")) or any(folder.glob("*.webm")),
            "selected": slug == selected,
        })

    print(json.dumps({
        "selected": selected,
        "active": active_qylock_theme(),
        "sddm_current": read_sddm_current(),
        "themes": themes,
    }))

def atomic_save(slug):
    QYLOCK.mkdir(parents=True, exist_ok=True)
    fd, temp = tempfile.mkstemp(prefix="theme.", dir=QYLOCK)
    try:
        with os.fdopen(fd, "w") as file:
            file.write(slug + "\n")
        os.replace(temp, CONFIG)
    except Exception:
        try:
            os.unlink(temp)
        except OSError:
            pass
        raise

def save(slug):
    resolve_theme(slug)
    result = subprocess.run(
        ["pkexec", "/usr/bin/python3", str(INSTALLER), "apply", slug],
        text=True,
        capture_output=True,
    )
    if result.returncode != 0:
        message = (result.stderr or result.stdout).strip()
        raise RuntimeError(message or "Could not apply the SDDM theme.")
    atomic_save(slug)
    print(result.stdout.strip() or ("Applied SDDM theme: " + slug))

def preview(slug):
    folder = resolve_theme(slug)
    env = os.environ.copy()
    imports = str(QYLOCK / "imports")
    env["QML2_IMPORT_PATH"] = imports + (
        ":" + env["QML2_IMPORT_PATH"] if env.get("QML2_IMPORT_PATH") else ""
    )
    env["QML_XHR_ALLOW_FILE_READ"] = "1"
    env["QS_THEME"] = slug
    env["QS_THEME_PATH"] = str(folder)
    env["QS_TESTING"] = "1"
    env["XDG_SESSION_TYPE"] = "x11"

    subprocess.Popen(
        ["quickshell", "-p", str(QYLOCK / "lock_shell.qml")],
        env=env,
        cwd=str(QYLOCK),
        start_new_session=True,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    print("Preview opened: " + slug)

def main():
    if len(sys.argv) == 2 and sys.argv[1] == "get":
        get()
    elif len(sys.argv) == 3 and sys.argv[1] == "save":
        save(sys.argv[2])
    elif len(sys.argv) == 3 and sys.argv[1] == "preview":
        preview(sys.argv[2])
    else:
        raise ValueError("Usage: lock-settings.py get | save THEME | preview THEME")

if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        print(str(error), file=sys.stderr)
        sys.exit(1)
