#!/usr/bin/env bash
set -euo pipefail

config=${XDG_CONFIG_HOME:-"$HOME/.config"}
state=${XDG_STATE_HOME:-"$HOME/.local/state"}/vyeos/current-theme
slug=wallpaper
[[ -s $state ]] && IFS= read -r slug < "$state"
file=$config/vyeos/themes/$slug.json
[[ -f $file ]] || exit 1

c() { jq -er ".colors.$1" "$file"; }

mkdir -p "$config/kitty/themes"
out=$config/kitty/themes/vyeos.conf
tmp=$(mktemp "$out.XXXXXX")

{
  printf '# Generated from %s\n' "$slug"
  printf 'foreground %s\nbackground %s\n' "$(c foreground)" "$(c bg0)"
  printf 'selection_foreground %s\nselection_background %s\n' "$(c foreground)" "$(c bg3)"
  printf 'cursor %s\ncursor_text_color %s\n' "$(c primary)" "$(c bg_dim)"
  printf 'url_color %s\n' "$(c blue)"
  printf 'active_border_color %s\ninactive_border_color %s\n' "$(c primary)" "$(c bg3)"
  printf 'active_tab_foreground %s\nactive_tab_background %s\n' "$(c bg_dim)" "$(c primary)"
  printf 'inactive_tab_foreground %s\ninactive_tab_background %s\n' "$(c muted)" "$(c bg1)"
  printf 'color0 %s\ncolor8 %s\n'   "$(c bg3)" "$(c bg4)"
  printf 'color1 %s\ncolor9 %s\n'   "$(c red)" "$(c red)"
  printf 'color2 %s\ncolor10 %s\n'  "$(c green)" "$(c green)"
  printf 'color3 %s\ncolor11 %s\n'  "$(c yellow)" "$(c yellow)"
  printf 'color4 %s\ncolor12 %s\n'  "$(c blue)" "$(c blue)"
  printf 'color5 %s\ncolor13 %s\n'  "$(c purple)" "$(c purple)"
  printf 'color6 %s\ncolor14 %s\n'  "$(c aqua)" "$(c aqua)"
  printf 'color7 %s\ncolor15 %s\n'  "$(c muted)" "$(c foreground)"
} > "$tmp"
mv -f -- "$tmp" "$out"

# Tell every running kitty window to reload its config
pkill -USR1 -x kitty >/dev/null 2>&1 || true
