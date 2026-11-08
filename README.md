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

## Keyboard Shortcuts

The desktop uses the **Super (Windows) key** as its primary modifier.

### Applications & Shell

| Shortcut | Action |
|---|---|
| `Super + Enter` | Open terminal |
| `Super + E` | Open file manager |
| `Super + T` | Open text editor |
| `Super + C` | Open calculator |
| `Super + W` | Open browser |
| `Super + Space` | Toggle application launcher |
| `Super + .` | Open emoji picker |
| `Super + X` | Toggle Control Center |
| `Super + Z` | Toggle shell settings |
| `Super + A` | Toggle notifications |
| `Super + V` | Open clipboard history |
| `Super + Shift + W` | Open wallpaper selector |
| `Super + L` | Lock screen |
| `Super + Alt + C` | Open session menu |
| `Ctrl + Shift + Esc` | Open system monitor (btop) |

### Window Management

| Shortcut | Action |
|---|---|
| `Super + Q` | Close active window |
| `Super + Esc` | Kill active window |
| `Super + Alt + Space` | Toggle floating mode |
| `Super + D` | Toggle fullscreen mode |
| `Super + F` | Toggle fullscreen |
| `Super + J` | Toggle split layout |
| `Super + Arrow Keys` | Change window focus |
| `Alt + Tab` | Cycle through windows |
| `Super + Tab` | Open window switcher |
| `Super + Mouse Left` | Move window |
| `Super + Mouse Right` | Resize window |

### Window Movement

| Shortcut | Action |
|---|---|
| `Super + Shift + Arrow Keys` | Move window |
| `Super + Shift + 1/2/3` | Move window to monitor |
| `Super + Shift + Ctrl + Arrow Left/Right` | Move window to adjacent workspace |
| `Super + Shift + S` | Move window to special workspace |

### Workspaces & Monitors

| Shortcut | Action |
|---|---|
| `Super + 1/2/3` | Focus monitor |
| `Super + Alt + 1–9/0` | Switch to workspace |
| `Super + Ctrl + 1–9/0` | Switch to relative workspace |
| `Super + Ctrl + Left/Right` | Switch to adjacent workspace |
| `Super + Ctrl + Down` | Switch to next empty workspace |
| `Super + S` | Toggle special workspace |

### Screenshots & Utilities

| Shortcut | Action |
|---|---|
| `Print` | Take region screenshot |
| `Super + Print` | Take fullscreen screenshot |
| `Super + P` | Pick screen color |
| `Super + Plus/Minus` | Adjust cursor zoom |

### Hardware Controls

| Key | Action |
|---|---|
| Volume Up / Down | Adjust volume |
| Volume Mute | Toggle audio mute |
| Microphone Mute | Toggle microphone mute |
| Play / Pause | Toggle media playback |
| Previous / Next | Change media track |
| Brightness Up / Down | Adjust screen brightness |
| Calculator key | Open calculator |

*Note: Workspace shortcuts support the configured number of workspaces. Some application shortcuts depend on the corresponding applications being installed.*
