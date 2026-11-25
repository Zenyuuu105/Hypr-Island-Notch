#!/usr/bin/env python3
import colorsys
import json
import os
import re
import shutil
import sys
from pathlib import Path

HOME = Path.home()

# All paths can be overridden through environment variables.
PALETTES = Path(os.environ.get(
    "IRIS_PALETTES_DIR",
    str(HOME / ".cache/iris/wallpaper-palettes")
)).expanduser()

THEMES = Path(os.environ.get(
    "IRIS_THEMES_DIR",
    str(HOME / ".config/vyeos/themes")
)).expanduser()

WALLPAPERS = Path(os.environ.get(
    "IRIS_WALLPAPERS_DIR",
    str(HOME / "Pictures/Wallpapers")
)).expanduser()

# Wallpaper source and generated wallpaper folders share this library.
SOURCE = WALLPAPERS

EXTENSIONS = (".png", ".jpg", ".jpeg", ".webp")

NAMES = {
    "1378545": "Indigo Reverie",
    "cute-anime-background-Anime-Wallpapers-evergarden-ghibli-field": "Evergarden Field",
    "cute-anime-background-Anime-Wallpapers-evergarden-konosuba-kamisama-ghibli": "Forest Aurora",
    "cute-anime-background-Anime-Wallpapers-ghibli-ponyo-scenery": "Ponyo Seascape",
    "Gemini_Generated_Image_9szn899szn899szn": "Gemini Earthlight",
    "Gemini_Generated_Image_kovs73kovs73kovs": "Gemini Blue Hour",
    "wallhaven-7jm33o_1920x1080": "Wallhaven Blush",
    "wallhaven-85mk1k_1920x1080": "Wallhaven Verdant",
    "wallhaven-d825k3_1920x1080": "Wallhaven Meadow",
    "wallhaven-n6w396_1920x1080": "Wallhaven Citrine",
    "wallhaven-pomr6m_1920x1080": "Wallhaven Lime",
    "wallhaven-qr5mdl_1920x1080": "Wallhaven Terracotta",
    "wallhaven-qrgdzq_1920x1080": "Wallhaven Lagoon",
    "wallhaven-v9gkgm_1920x1080": "Wallhaven Azure",
    "wallhaven-w5w866_1920x1080": "Wallhaven Forest",
    "wallhaven-xe85j3_1920x1080": "Wallhaven Ember",
    "wallhaven-yqkl97_1920x1080": "Wallhaven Orchid",
    "wallpaper-cat-cute-Anime-Wallpapers-flcl-tokyo-hyouka-scenery": "Tokyo Hyouka",
    "wp16237692-pastel-sky-desktop-wallpapers": "Pastel Horizon",
}

FALLBACKS = {
    "red": "#e67e80",
    "orange": "#e69875",
    "yellow": "#dbbc7f",
    "green": "#a7c080",
    "aqua": "#83c092",
    "blue": "#7fbbb3",
    "purple": "#d699b6",
}


def rgb(color):
    value = color.lstrip("#")
    if not re.fullmatch(r"[0-9a-fA-F]{6}", value):
        raise ValueError(f"Invalid color: {color}")
    return tuple(int(value[i:i+2], 16) / 255 for i in (0, 2, 4))


def hx(values):
    return "#{:02x}{:02x}{:02x}".format(
        *(max(0, min(255, round(v * 255))) for v in values)
    )


def mix(a, b, amount):
    return hx(tuple(x + (y-x)*amount for x, y in zip(rgb(a), rgb(b))))


def hue(color):
    h, lightness, saturation = colorsys.rgb_to_hls(*rgb(color))
    return h * 360, saturation


def distance(a, b):
    d = abs(a-b)
    return min(d, 360-d)


def choose(target, candidates, fallback, used):
    options = []
    for color in candidates:
        h, saturation = hue(color)
        if saturation < 0.18 or color.lower() in used:
            continue
        options.append((distance(h, target), -saturation, color))
    options.sort()
    if options and options[0][0] <= 48:
        used.add(options[0][2].lower())
        return options[0][2]
    return fallback


def folder_color(accent):
    h, saturation = hue(accent)
    if saturation < 0.2:
        return "bluegrey"
    for limit, name in [
        (15, "red"), (40, "orange"), (70, "yellow"),
        (165, "green"), (195, "teal"), (255, "blue"),
        (285, "violet"), (330, "magenta"), (345, "pink")
    ]:
        if h < limit:
            return name
    return "red"


def convert(data, stem):
    dark = bool(data.get("dark", True))
    bg, surface = data["bg"], data["surface"]
    fg, dim, accent = data["fg"], data["dim"], data["accent"]

    candidates = [
        v for k, v in data.items()
        if k not in ("bg", "surface", "fg", "dim")
        and isinstance(v, str)
        and re.fullmatch(r"#[0-9a-fA-F]{6}", v)
    ]

    used = set()
    semantic = {}
    for key, target in [
        ("red", 0), ("orange", 25), ("yellow", 50),
        ("green", 120), ("aqua", 165), ("blue", 210),
        ("purple", 275)
    ]:
        semantic[key] = choose(target, candidates, FALLBACKS[key], used)

    colors = {
        "bg_dim": mix(bg, "#000000" if dark else "#ffffff",
                      0.25 if dark else 0.06),
        "bg0": bg,
        "bg1": surface,
        "bg2": mix(surface, dim, 0.35),
        "bg3": mix(surface, dim, 0.70),
        "bg4": dim,
        "primary_container": mix(bg, accent, 0.22),
        "secondary_container": mix(bg, semantic["yellow"], 0.22),
        "foreground": fg,
        "muted": mix(fg, bg, 0.35),
        "muted_dark": mix(fg, bg, 0.55),
        **semantic,
        "primary": accent,
    }

    slug = "iris-" + re.sub(r"[^a-z0-9]+", "-", stem.lower()).strip("-")

    return {
        "name": NAMES.get(stem, stem.replace("-", " ").title()),
        "slug": slug,
        "appearance": "dark" if dark else "light",
        "colors": colors,
        "applications": {
            "neovim": "everforest",
            "alacritty": "wallpaper",
            "folder_color": folder_color(accent),
        },
        "generated": True,
    }


def main():
    install = "--install" in sys.argv[1:]

    if not PALETTES.is_dir() or not SOURCE.is_dir() or not THEMES.is_dir():
        sys.exit("ERROR: A required source or existing theme directory is missing.")

    jobs = []
    skipped = []
    errors = []

    for directory in sorted(p for p in PALETTES.iterdir() if p.is_dir()):
        stem = directory.name
        palette_file = directory / "colors.json"

        if not palette_file.is_file():
            errors.append(f"{stem}: missing colors.json")
            continue

        try:
            data = json.loads(palette_file.read_text())
            for key in ("bg", "surface", "fg", "dim", "accent"):
                rgb(data[key])

            theme = convert(data, stem)
            slug = theme["slug"]
            theme_file = THEMES / f"{slug}.json"
            folder = WALLPAPERS / slug

            # Prefer an image already inside its theme wallpaper folder.
            wallpaper = None
            if folder.is_dir():
                wallpaper = next(
                    (p for p in sorted(folder.iterdir())
                     if p.is_file() and p.suffix.lower() in EXTENSIONS),
                    None
                )
            else:
                # Retain support for the older flat wallpaper layout.
                wallpaper = next(
                    (SOURCE / (stem + ext) for ext in EXTENSIONS
                     if (SOURCE / (stem + ext)).is_file()),
                    None
                )

            if theme_file.exists() and folder.is_dir():
                if wallpaper is None:
                    errors.append(
                        f"{stem}: theme and folder exist, but the folder has no wallpaper"
                    )
                    continue

                try:
                    existing = json.loads(theme_file.read_text())
                    if existing.get("slug") != slug:
                        errors.append(f"{stem}: existing theme JSON has an unexpected slug")
                        continue
                except Exception as error:
                    errors.append(f"{stem}: existing theme JSON is invalid: {error}")
                    continue

                skipped.append(f"{slug}: already installed")
                continue

            if theme_file.exists() and not folder.is_dir():
                errors.append(f"{stem}: theme JSON exists but wallpaper folder is missing")
                continue

            if folder.is_dir() and wallpaper is None:
                errors.append(f"{stem}: wallpaper folder exists but contains no image")
                continue

            if wallpaper is None:
                skipped.append(f"{slug}: matching wallpaper not found")
                continue

            # create_folder is false when completing a folder that already
            # contains its wallpaper; existing files are never overwritten.
            jobs.append((theme, wallpaper, not folder.exists()))

        except Exception as error:
            errors.append(f"{stem}: {error}")

    if errors:
        print("Nothing installed. Problems found:")
        print("\n".join(errors))
        sys.exit(1)

    print(f"New themes ready: {len(jobs)}")
    print(f"Skipped: {len(skipped)}")
    for item in skipped:
        print(f"  SKIP  {item}")

    if not jobs:
        print("\nNothing new to install. Existing files were left untouched.")
        return

    slugs = [theme["slug"] for theme, _, _ in jobs]
    if len(slugs) != len(set(slugs)):
        sys.exit("Duplicate generated slugs. Nothing installed.")

    print("\nThemes ready:")
    for theme, wallpaper, create_folder in jobs:
        action = "create wallpaper folder" if create_folder else "reuse existing wallpaper folder"
        print(
            f'{theme["name"]:<25} {theme["slug"]:<60} '
            f'{theme["colors"]["primary"]}  [{action}]'
        )

    if not install:
        print("\nDRY RUN ONLY — no files changed.")
        print("Run with --install after reviewing this list.")
        return

    created = []
    try:
        for theme, wallpaper, create_folder in jobs:
            slug = theme["slug"]
            folder = WALLPAPERS / slug
            theme_file = THEMES / f"{slug}.json"
            folder_was_created = False

            if create_folder:
                folder.mkdir()
                folder_was_created = True

            created.append((theme_file, folder, folder_was_created))
            temp_file = theme_file.with_suffix(".json.tmp")

            try:
                if create_folder:
                    destination = folder / wallpaper.name
                    try:
                        os.link(wallpaper, destination)
                    except OSError:
                        shutil.copy2(wallpaper, destination)

                temp_file.write_text(json.dumps(theme, indent=2) + "\n")
                temp_file.replace(theme_file)
            finally:
                temp_file.unlink(missing_ok=True)

    except Exception as error:
        print(f"Installation failed: {error}")
        for theme_file, folder, folder_was_created in reversed(created):
            theme_file.unlink(missing_ok=True)
            if folder_was_created:
                shutil.rmtree(folder, ignore_errors=True)
        sys.exit(1)

    print(f"\nSuccessfully installed {len(created)} new Iris themes.")
    print("Existing themes and wallpaper folders were left untouched.")
    print("Your current theme and theme state were not changed.")


if __name__ == "__main__":
    main()
