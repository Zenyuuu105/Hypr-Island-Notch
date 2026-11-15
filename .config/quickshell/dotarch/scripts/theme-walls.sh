#!/usr/bin/env bash
# prints "<slug>\t<wallpaper path>" for every theme folder
S="${XDG_STATE_HOME:-$HOME/.local/state}/vyeos/wallpapers"
for d in "$HOME"/Pictures/Wallpapers/*/; do
  s=$(basename "$d"); f=""
  [[ -s $S/$s ]] && IFS= read -r f < "$S/$s"
  if [[ ! -f $f ]]; then
    f=$(find "$d" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) | sort | head -1)
  fi
  [[ -n $f ]] && printf '%s\t%s\n' "$s" "$f"
done
