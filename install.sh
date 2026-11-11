#!/usr/bin/env bash
# Fresh Arch Linux / CachyOS installer for Zenyuuu105/dotfiles
set -Eeuo pipefail

ORIGINAL_HOME="/home/entity303069"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$HOME/.dotfiles-backup/$STAMP"

DRY=0
PKGS=1
OPTIONAL=0
DEPLOY=1

INSTALLED=()
REPO_PKGS=()
AUR_PKGS=()

declare -A SEEN=()

usage() {
    cat <<'USAGE'
Usage: ./install.sh [options]

  --dry-run      Preview changes without modifying the system
  --no-packages  Copy configurations only
  --optional     Also install optional applications and AUR packages
  --packages-only Install packages/services without changing user files
  -h, --help     Show this help

The installer:
  - Updates existing system packages
  - Installs missing dependencies
  - Uses an existing paru/yay or bootstraps paru
  - Backs up existing configurations
  - Deploys wallpapers without overwriting existing files
  - Enables required system and user services
USAGE
}

for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY=1 ;;
        --no-packages) PKGS=0 ;;
        --optional) OPTIONAL=1 ;;
        --packages-only) DEPLOY=0 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown option: $arg" >&2; usage; exit 1 ;;
    esac
done

say() {
    printf '\033[1;34m==>\033[0m %s\n' "$*"
}

warn() {
    printf '\033[1;33m!!\033[0m %s\n' "$*" >&2
}

die() {
    printf '\033[1;31mERROR:\033[0m %s\n' "$*" >&2
    exit 1
}

run() {
    if (( DRY )); then
        printf '   [dry-run]'
        printf ' %q' "$@"
        printf '\n'
    else
        "$@"
    fi
}

read_list() {
    awk 'NF && $1 !~ /^#/ {print $1}' "$1"
}

add_package() {
    local package="$1"

    [[ -n "$package" ]] || return 0
    [[ -n "${SEEN[$package]+x}" ]] && return 0

    SEEN["$package"]=1

    if pacman -Si "$package" >/dev/null 2>&1; then
        REPO_PKGS+=("$package")
    else
        AUR_PKGS+=("$package")
    fi
}

classify_file() {
    local file="$1"
    local package

    [[ -f "$file" ]] || die "Missing package list: $file"

    while IFS= read -r package; do
        add_package "$package"
    done < <(read_list "$file")
}

install_aur_helper() {
    local build_dir

    if command -v paru >/dev/null 2>&1; then
        AUR_HELPER="paru"
        return
    fi

    if command -v yay >/dev/null 2>&1; then
        AUR_HELPER="yay"
        return
    fi

    say "No AUR helper found. Installing paru."

    if (( DRY )); then
        run sudo pacman -S --needed base-devel git
        say "[dry-run] Would clone and build paru from the AUR"
        AUR_HELPER="paru"
        return
    fi

    sudo pacman -S --needed base-devel git

    build_dir="$(mktemp -d)"
    trap 'rm -rf "${build_dir:-}"' EXIT

    git clone --depth 1 https://aur.archlinux.org/paru.git "$build_dir/paru"

    (
        cd "$build_dir/paru"
        makepkg -si
    )

    AUR_HELPER="paru"
}

install_packages() {
    say "Updating installed system packages"

    # Upgrade existing software before installing dependencies.
    run sudo pacman -Syu

    say "Checking required packages"
    classify_file "$REPO_DIR/packages/required.txt"

    if (( OPTIONAL )); then
        say "Checking optional packages"
        classify_file "$REPO_DIR/packages/optional.txt"
        classify_file "$REPO_DIR/packages/aur.txt"
    fi

    if (( ${#REPO_PKGS[@]} )); then
        say "Installing/updating official repository packages"
        run sudo pacman -S --needed "${REPO_PKGS[@]}"
    fi

    if (( ${#AUR_PKGS[@]} )); then
        say "Installing/updating AUR packages"
        install_aur_helper
        run "$AUR_HELPER" -Syu --needed "${AUR_PKGS[@]}"
    fi

    if (( ! ${#REPO_PKGS[@]} && ! ${#AUR_PKGS[@]} )); then
        say "No packages need installing."
    fi
}

backup_and_copy() {
    local src="$1"
    local dest="$2"
    local rel

    if [[ -e "$dest" || -L "$dest" ]]; then
        rel="${dest#"$HOME"/}"

        run mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
        run mv "$dest" "$BACKUP_DIR/$rel"
    fi

    run mkdir -p "$(dirname "$dest")"
    run cp -a "$src" "$dest"

    INSTALLED+=("$dest")
}

enable_services() {
    say "Enabling system services"

    run sudo systemctl enable --now NetworkManager.service
    run sudo systemctl enable --now bluetooth.service
    run sudo systemctl enable --now power-profiles-daemon.service

    say "Configuring PipeWire user services"

    if (( DRY )); then
        run systemctl --user daemon-reload
        run systemctl --user enable --now \
            pipewire.socket pipewire-pulse.socket wireplumber.service
    elif systemctl --user daemon-reload; then
        systemctl --user enable --now \
            pipewire.socket pipewire-pulse.socket wireplumber.service \
            || warn "Could not start PipeWire user services. Check them after logging in."
    else
        warn "User systemd bus unavailable. PipeWire services can be enabled after login."
    fi
}

# --------------------------------------------------
# Initial checks
# --------------------------------------------------

(( EUID != 0 )) || die "Run this installer as your normal user, not root."

command -v pacman >/dev/null 2>&1 \
    || die "This installer requires Arch Linux or an Arch-based distribution."

command -v sudo >/dev/null 2>&1 \
    || die "sudo is required. Install it and configure your user first."

[[ -d "$REPO_DIR/.config" ]] \
    || die "The repository .config directory is missing."

say "Installing from $REPO_DIR"

if (( DRY )); then
    say "Dry-run mode: no changes will be made."
fi

# --------------------------------------------------
# Packages
# --------------------------------------------------

if (( PKGS )); then
    install_packages
else
    say "Skipping package installation."
fi

if (( DEPLOY )); then

# --------------------------------------------------
# Configurations
# --------------------------------------------------

say "Deploying configuration files"

for src in "$REPO_DIR"/.config/*; do
    [[ -e "$src" || -L "$src" ]] || continue
    backup_and_copy "$src" "$HOME/.config/$(basename "$src")"
done

# --------------------------------------------------
# Local scripts
# --------------------------------------------------

if [[ -d "$REPO_DIR/.local/bin" ]]; then
    say "Deploying local scripts"

    for src in "$REPO_DIR"/.local/bin/*; do
        [[ -e "$src" || -L "$src" ]] || continue

        dest="$HOME/.local/bin/$(basename "$src")"
        backup_and_copy "$src" "$dest"
        run chmod +x "$dest"
    done
fi

# --------------------------------------------------
# iris (wallpaper color tool)
# --------------------------------------------------

if command -v pipx >/dev/null 2>&1; then
    say "Installing iris"
    run pipx install --force "git+https://github.com/Harman1307/iris.git"
else
    warn "pipx not found, skipping iris. Install python-pipx and rerun."
fi

# --------------------------------------------------
# Spicetify (only if Spotify and spicetify are installed)
# --------------------------------------------------

if command -v spicetify >/dev/null 2>&1 \
    && { command -v spotify-launcher >/dev/null 2>&1 || command -v spotify >/dev/null 2>&1; }; then
    say "Applying Spicetify"
    run spicetify backup apply \
        || warn "Spicetify failed. Open Spotify once, then run: spicetify backup apply"
else
    warn "Spicetify or Spotify not installed, skipping. Run ./install.sh --optional --packages-only, open Spotify once, then: spicetify backup apply"
fi

# --------------------------------------------------
# External monitor brightness (ddcutil needs i2c)
# --------------------------------------------------

if (( PKGS )); then
    say "Setting up i2c for ddcutil"
    run sudo groupadd -f i2c
    run sudo usermod -aG i2c "$USER"
    echo i2c-dev | run sudo tee /etc/modules-load.d/i2c-dev.conf >/dev/null
    warn "Log out and back in so the i2c group takes effect."
fi

# --------------------------------------------------
# Wallpapers
# --------------------------------------------------

if [[ -d "$REPO_DIR/Pictures" ]]; then
    say "Deploying wallpapers (existing files will not be overwritten)"

    run mkdir -p "$HOME/Pictures"
    run cp -an "$REPO_DIR/Pictures/." "$HOME/Pictures/"
fi

# --------------------------------------------------
# Home-directory portability
# --------------------------------------------------

if [[ "$HOME" != "$ORIGINAL_HOME" && "$DRY" -eq 0 ]]; then
    say "Adjusting hardcoded home paths"

    grep -rlIF "$ORIGINAL_HOME" "${INSTALLED[@]}" 2>/dev/null |
        xargs -r sed -i "s|$ORIGINAL_HOME|$HOME|g" || true
fi

# --------------------------------------------------
# Default theme (creates the Vyeos icon variants)
# --------------------------------------------------

THEME_SCRIPT="$HOME/.config/quickshell/dotarch/scripts/theme-system.sh"

if [[ -x "$THEME_SCRIPT" && "$DRY" -eq 0 ]]; then
    say "Applying default theme"
    PATH="$HOME/.local/bin:$PATH" "$THEME_SCRIPT" apply deep-space \
        || warn "Could not apply the default theme. Pick one after logging in."
fi

fi # DEPLOY

# --------------------------------------------------
# Services and desktop setup
# --------------------------------------------------

if (( PKGS && ! DRY )); then
    enable_services

    if command -v xdg-user-dirs-update >/dev/null 2>&1; then
        xdg-user-dirs-update
    fi

    if command -v fc-cache >/dev/null 2>&1; then
        fc-cache -f
    fi
elif (( PKGS && DRY )); then
    enable_services
fi

# --------------------------------------------------
# Finish
# --------------------------------------------------

say "Installation completed."

echo
echo "Next steps:"
echo "  1. Reboot or log out and start a Hyprland UWSM session."
echo "  2. If Dotarch does not appear, run: qs --no-duplicate --path ~/.config/quickshell/dotarch"
echo "  3. Optional applications can be installed with: ./install.sh --optional --packages-only"
echo "  4. After installing Spotify, open it once, then run: spicetify backup apply"

if (( DRY )); then
    echo
    echo "This was only a preview. No changes were made."
else
    echo
    echo "Previous configurations are backed up in:"
    echo "  $BACKUP_DIR"
fi