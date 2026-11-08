# Dotfiles

My Arch Linux / CachyOS desktop setup.

## Desktop

- Hyprland with UWSM
- Quickshell Dotarch with animated notch
- Dynamic themes with Matugen
- Kitty, Fish and Starship
- PipeWire and EasyEffects
- Clipboard history, screenshots and recording
- GTK and Qt theming
- Wallpaper collection with theme-specific folders


## Keyboard Shortcuts

| Shortcut | Action |
|---|---|
| `Super` | Open application launcher |
| `Super + Shift + T` | Open theme switcher |
| `Super + Shift + W` | Open wallpaper switcher |
| `Super + W` | Open secondary wallpaper switcher |
| `Super + Q` | Close active window |
| `Alt + Enter` | Open terminal |
| `Super + L` | Lock screen |
| `Fn + Print Screen` | Open screenshot and screen recording panel |
| `Fn + Shift + Print Screen` | Take screenshot directly |
| `Super + E` | Open file explorer |
| `Super + V` | Open clipboard history |
| `Super + Space` | Open Control Center |
| `Super + I` | Open Settings |
  
## Installation

Start with a working Arch Linux or CachyOS installation with internet access,
Git and sudo configured for your user.

Clone the repository:

    git clone https://github.com/Zenyuuu105/dotfiles.git
    cd dotfiles

Run the installer:

    ./install.sh

The installer updates the system, installs required dependencies, deploys
configurations and scripts, copies wallpapers, and enables required services.

Optional applications (during initial setup):

    ./install.sh --optional

Install optional applications later without redeploying configurations:

    ./install.sh --optional --packages-only

Preview changes without applying them:

    ./install.sh --dry-run

Copy configurations without installing packages:

    ./install.sh --no-packages

## Package management

Packages are listed in:

- `packages/required.txt`
- `packages/optional.txt`
- `packages/aur.txt`

The installer checks enabled repositories first and uses an AUR helper for
packages unavailable in those repositories. It uses paru when available,
then yay, and bootstraps paru if necessary.

## Backups

Existing configuration files are moved to:

    ~/.dotfiles-backup/

Existing wallpaper files are preserved and are not overwritten.

## Login

After installation, log out or reboot and select the Hyprland UWSM session
from your login manager. The installer does not automatically replace or
enable your display manager.
