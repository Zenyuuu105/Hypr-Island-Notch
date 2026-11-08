
#!/usr/bin/env bash

img="$1"
log="$HOME/.cache/43pr/wallpaper.log"

mkdir -p "$HOME/.cache/43pr"
exec >>"$log" 2>&1

echo "---- $(date) ----"
echo "Selected wallpaper: $img"

if [[ ! -f "$img" ]]; then
    echo "ERROR: Wallpaper file not found: $img"
    exit 1
fi

# Reuse the running daemon; start one if needed.
if ! awww query >/dev/null 2>&1; then
    awww-daemon &
    for i in {1..30}; do
        sleep 0.2
        if awww query >/dev/null 2>&1; then
            break
        fi
    done
fi

if ! awww query >/dev/null 2>&1; then
    echo "ERROR: awww daemon did not become available"
    exit 1
fi

awww img "$img" --transition-type grow --transition-duration 1
status=$?
echo "awww exit code: $status"

if [[ $status -eq 0 ]]; then
    python3 "$HOME/.config/43pr/bin/theme.py" wallpaper "$img"
fi
