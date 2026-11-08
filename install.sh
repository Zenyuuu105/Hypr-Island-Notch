#!/usr/bin/env bash
# Installer for Zenyuuu105/dotfiles (Arch / CachyOS, Hyprland + Quickshell)
set -euo pipefail

ORIGINAL_HOME="/home/entity303069"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$HOME/.dotfiles-backup/$STAMP"
DRY=0; PKGS=1; OPTIONAL=0
INSTALLED=()

usage() {
cat <<'USAGE'
Usage: ./install.sh [options]

  --dry-run      show what would happen, change nothing
  --no-packages  copy the configs only, do not install packages
  --optional     also install packages/optional.txt and packages/aur.txt
  -h, --help     show this help

Existing files are moved to ~/.dotfiles-backup/<timestamp>/ before being replaced.
USAGE
}

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY=1 ;;
    --no-packages) PKGS=0 ;;
    --optional) OPTIONAL=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $arg" >&2; usage; exit 1 ;;
  esac
done

say()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }
run()  { if [ "$DRY" -eq 1 ]; then printf '   [dry-run] %s\n' "$*"; else "$@"; fi; }

if [ "$(id -u)" -eq 0 ]; then echo "Run as your normal user, not root." >&2; exit 1; fi
if ! command -v pacman >/dev/null; then echo "This installer needs an Arch-based system (pacman)." >&2; exit 1; fi

read_list() { grep -vE '^[[:space:]]*(#|$)' "$1" | awk '{print $1}'; }

install_native() {
  local file="$1" ok=() missing=() p
  while read -r p; do
    if pacman -Si "$p" >/dev/null 2>&1; then ok+=("$p"); else missing+=("$p"); fi
  done < <(read_list "$file")
  if [ "${#missing[@]}" -gt 0 ]; then warn "Not found in your repos, skipped: ${missing[*]}"; fi
  if [ "${#ok[@]}" -gt 0 ]; then run sudo pacman -S --needed "${ok[@]}"; fi
}

install_aur() {
  local helper="" h p pkgs=()
  for h in paru yay; do
    if command -v "$h" >/dev/null; then helper="$h"; break; fi
  done
  if [ -z "$helper" ]; then warn "No AUR helper (paru or yay) found, skipping AUR packages."; return 0; fi
  while read -r p; do pkgs+=("$p"); done < <(read_list "$1")
  if [ "${#pkgs[@]}" -gt 0 ]; then run "$helper" -S --needed "${pkgs[@]}"; fi
}

backup_and_copy() {  # $1 = source in repo, $2 = destination
  local src="$1" dest="$2" rel
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    rel="${dest#"$HOME"/}"
    run mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
    run mv "$dest" "$BACKUP_DIR/$rel"
  fi
  run mkdir -p "$(dirname "$dest")"
  run cp -a "$src" "$dest"
  INSTALLED+=("$dest")
}

say "Installing from $REPO_DIR"
if [ "$DRY" -eq 1 ]; then say "Dry run: nothing will be changed"; fi

if [ "$PKGS" -eq 1 ]; then
  say "Installing required packages"
  install_native "$REPO_DIR/packages/required.txt"
  if [ "$OPTIONAL" -eq 1 ]; then
    say "Installing optional packages"
    install_native "$REPO_DIR/packages/optional.txt"
    install_aur "$REPO_DIR/packages/aur.txt"
  fi
fi

say "Copying configs to ~/.config (old ones are backed up to $BACKUP_DIR)"
for src in "$REPO_DIR"/.config/*; do
  [ -e "$src" ] || continue
  backup_and_copy "$src" "$HOME/.config/$(basename "$src")"
done

if [ -d "$REPO_DIR/.local/bin" ]; then
  say "Copying scripts to ~/.local/bin"
  for src in "$REPO_DIR"/.local/bin/*; do
    [ -e "$src" ] || continue
    backup_and_copy "$src" "$HOME/.local/bin/$(basename "$src")"
    run chmod +x "$HOME/.local/bin/$(basename "$src")"
  done
fi

if [ -d "$REPO_DIR/Pictures" ]; then
  say "Copying wallpapers to ~/Pictures (existing files are kept)"
  run mkdir -p "$HOME/Pictures"
  run cp -an "$REPO_DIR/Pictures/." "$HOME/Pictures/"
fi

if [ "$HOME" != "$ORIGINAL_HOME" ] && [ "$DRY" -eq 0 ]; then
  say "Rewriting $ORIGINAL_HOME to $HOME in the installed configs"
  grep -rlIF "$ORIGINAL_HOME" "${INSTALLED[@]}" 2>/dev/null | xargs -r sed -i "s|$ORIGINAL_HOME|$HOME|g" || true
fi

say "Done."
echo "Next steps:"
echo "  1. Log out and start a Hyprland session (choose the UWSM entry if your login manager has one)."
echo "  2. If the shell does not appear, run: qs -c dotarch"
if [ "$DRY" -eq 0 ]; then echo "  3. Your previous configs are in $BACKUP_DIR"; fi
