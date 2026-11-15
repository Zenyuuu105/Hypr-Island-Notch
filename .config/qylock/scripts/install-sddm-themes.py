#!/usr/bin/env python3
import configparser
import os
import pwd
import re
import shutil
import stat
import sys
import tempfile
from pathlib import Path

SDDM_THEMES = Path("/usr/share/sddm/themes")
SDDM_CONFIG = Path("/etc/sddm.conf.d/theme.conf")
PREFIX = "qylock-"

def user_home():
    uid = os.environ.get("PKEXEC_UID")
    if not uid or not uid.isdigit():
        raise RuntimeError("Run this installer through pkexec.")
    return Path(pwd.getpwuid(int(uid)).pw_dir)

HOME = user_home()
SOURCE = HOME / ".config/qylock/themes"

def metadata(folder):
    path = folder / "metadata.desktop"
    parser = configparser.ConfigParser(interpolation=None)
    if not path.is_file():
        raise RuntimeError(f"Missing metadata.desktop: {folder.name}")
    parser.read(path)
    if not parser.has_section("SddmGreeterTheme"):
        raise RuntimeError(f"Invalid SDDM metadata: {folder.name}")
    section = parser["SddmGreeterTheme"]
    main = section.get("MainScript", "Main.qml")
    if section.get("QtVersion", "") != "6":
        raise RuntimeError(f"Not a Qt 6 theme: {folder.name}")
    if not (folder / main).is_file():
        raise RuntimeError(f"Missing {main}: {folder.name}")
    return main

def theme_sources():
    result = []

    for folder in sorted(SOURCE.iterdir(), key=lambda p: p.name.lower()):
        if not folder.is_dir() or folder.name == "clockwork":
            continue
        if not (folder / "metadata.desktop").is_file():
            continue

        metadata(folder)
        if not (folder / "theme.conf").is_file():
            if folder.name == "R1999_2" and (SOURCE / "R1999_1/theme.conf").is_file():
                pass
            else:
                raise RuntimeError(f"Missing theme.conf: {folder.name}")

        result.append((folder.name, folder))

    clockwork = SOURCE / "clockwork"
    if clockwork.is_dir():
        for folder in sorted(clockwork.iterdir(), key=lambda p: p.name.lower()):
            if not folder.is_dir():
                continue
            metadata(folder)
            if not (folder / "theme.conf").is_file():
                raise RuntimeError(f"Missing Clockwork theme.conf: {folder.name}")
            result.append(("clockwork-" + folder.name, folder))

    if not result:
        raise RuntimeError("No valid themes found.")

    return result

def install_one(slug, source):
    if not re.fullmatch(r"[A-Za-z0-9_-]+", slug):
        raise RuntimeError(f"Unsafe theme name: {slug}")

    destination = SDDM_THEMES / (PREFIX + slug)

    if destination.exists() and not (destination / ".qylock-managed").is_file():
        raise RuntimeError(
            f"Refusing to overwrite an unmanaged theme: {destination}"
        )

    stage = Path(tempfile.mkdtemp(prefix=".qylock-stage-", dir=SDDM_THEMES))
    old = None

    try:
        shutil.copytree(source, stage, dirs_exist_ok=True)

        # R1999_2 is missing its config; use its sibling variant's config.
        if not (stage / "theme.conf").is_file():
            sibling = SOURCE / "R1999_1" / "theme.conf"
            if slug == "R1999_2" and sibling.is_file():
                shutil.copy2(sibling, stage / "theme.conf")
            else:
                raise RuntimeError(f"No usable theme.conf for {slug}")

        metadata(stage)
        (stage / ".qylock-managed").write_text(
            "Managed by Qylock Desktop Settings\n"
        )

        for path in stage.rglob("*"):
            if path.is_symlink():
                raise RuntimeError(f"Symlink not permitted in theme: {path}")
            if path.is_dir():
                path.chmod(0o755)
            elif path.is_file():
                path.chmod(0o644)
        stage.chmod(0o755)

        if destination.exists():
            old = SDDM_THEMES / (".qylock-old-" + slug)
            if old.exists():
                shutil.rmtree(old)
            os.replace(destination, old)

        try:
            os.replace(stage, destination)
        except Exception:
            if old and old.exists():
                os.replace(old, destination)
            raise

        if old and old.exists():
            shutil.rmtree(old)

    finally:
        if stage.exists():
            shutil.rmtree(stage, ignore_errors=True)

def set_current(slug):
    destination = SDDM_THEMES / (PREFIX + slug)
    if not (destination / ".qylock-managed").is_file():
        raise RuntimeError(f"Theme is not installed: {slug}")

    SDDM_CONFIG.parent.mkdir(parents=True, exist_ok=True)
    original = SDDM_CONFIG.read_text() if SDDM_CONFIG.exists() else ""
    lines = original.splitlines()
    output = []
    in_theme = False
    found_section = False
    found_current = False

    for line in lines:
        stripped = line.strip()
        if stripped.startswith("[") and stripped.endswith("]"):
            if in_theme and not found_current:
                output.append("Current=" + PREFIX + slug)
                found_current = True
            in_theme = stripped.lower() == "[theme]"
            if in_theme:
                found_section = True
            output.append(line)
            continue

        if in_theme and re.match(r"^\s*Current\s*=", line, re.I):
            if not found_current:
                output.append("Current=" + PREFIX + slug)
                found_current = True
            continue

        output.append(line)

    if not found_section:
        if output and output[-1].strip():
            output.append("")
        output.extend(["[Theme]", "Current=" + PREFIX + slug])
    elif not found_current:
        output.append("Current=" + PREFIX + slug)

    content = "\n".join(output).rstrip() + "\n"
    mode = stat.S_IMODE(SDDM_CONFIG.stat().st_mode) if SDDM_CONFIG.exists() else 0o644

    fd, temp = tempfile.mkstemp(prefix=".qylock-sddm-", dir=SDDM_CONFIG.parent)
    try:
        with os.fdopen(fd, "w") as file:
            file.write(content)
        os.chmod(temp, mode)
        os.replace(temp, SDDM_CONFIG)
    except Exception:
        try:
            os.unlink(temp)
        except OSError:
            pass
        raise

def main():
    if len(sys.argv) == 2 and sys.argv[1] == "install-all":
        SDDM_THEMES.mkdir(parents=True, exist_ok=True)
        themes = theme_sources()
        print(f"Installing {len(themes)} Qylock themes into SDDM...")
        for index, (slug, source) in enumerate(themes, 1):
            install_one(slug, source)
            print(f"[{index}/{len(themes)}] Installed {slug}")
        print("All Qylock themes installed. SDDM was not restarted.")
    elif len(sys.argv) == 3 and sys.argv[1] == "apply":
        slug = sys.argv[2]
        if not re.fullmatch(r"[A-Za-z0-9_-]+", slug):
            raise RuntimeError("Invalid theme name.")
        set_current(slug)
        print(f"SDDM login theme set to {PREFIX}{slug}.")
    else:
        raise RuntimeError(
            "Usage: install-sddm-themes.py install-all | apply THEME"
        )

if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        print("Qylock SDDM installer:", error, file=sys.stderr)
        sys.exit(1)
