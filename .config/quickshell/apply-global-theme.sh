#!/usr/bin/env bash
WALLPAPER="$1"

if [ -f "$WALLPAPER" ]; then
    ~/.local/bin/iris "$WALLPAPER" --dark 1 >/dev/null 2>&1 || true
fi

# Grab the generated accent color from Iris cache if available, or fallback
IRIS_ACCENT=$(grep -m 1 "accent" ~/.cache/iris/colors.conf 2>/dev/null | awk '{print $2}')
if [ -z "$IRIS_ACCENT" ]; then
    IRIS_ACCENT="#7aa2f7"
fi

# Convert HEX to RGB for KDE
HEX="${IRIS_ACCENT#\#}"
R=$((16#${HEX:0:2}))
G=$((16#${HEX:2:2}))
B=$((16#${HEX:4:2}))
RGB_VAL="$R, $G, $B"

# Update KDE/Dolphin colors instantly
if command -v kwriteconfig6 >/dev/null 2>&1; then
    kwriteconfig6 --file kdeglobals --group General --key AccentColor "$RGB_VAL" >/dev/null 2>&1 || true
    kwriteconfig6 --file kdeglobals --group General --key LastUsedCustomAccentColor "$RGB_VAL" >/dev/null 2>&1 || true
    dbus-send --session --type=signal /KGlobalSettings org.kde.KGlobalSettings.notifyChange int32:0 int32:0 >/dev/null 2>&1 || true
fi

# Instant Desktop Reload
hyprctl reload >/dev/null 2>&1 || true
(sleep 0.2 && pkill quickshell; quickshell -p ~/.config/quickshell/dotarch &) &
