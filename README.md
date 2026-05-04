# victor-dotfiles

Personal configurations for a productivity-focused Hyprland environment on openSUSE Tumbleweed.

## Directory Structure

```text
.zshrc                          # Shell config (SSH + GPG agent, PATH, tools)
.zshrc.local                    # Machine-specific overrides (not tracked)
.gnupg/
└── gpg-agent.conf              # GPG agent passphrase cache (24h TTL)
.config/
├── hypr/
│   ├── conf/                   # Modular Hyprland settings
│   │   ├── autostart.conf
│   │   ├── custom.conf
│   │   ├── environment.conf
│   │   ├── input.conf
│   │   ├── keybindings.conf
│   │   ├── looks.conf
│   │   ├── monitors.conf
│   │   └── rules.conf
│   ├── scripts/                # Helper scripts (exit, recorder, monitor setup)
│   ├── hyprland.conf           # Main entry point (sources modular conf/)
│   ├── hypridle.conf           # Idle & sleep management
│   ├── hyprlock.conf           # Secure lockscreen
│   └── hyprpaper.conf          # Wallpaper management
├── dunst/                      # Notification daemon
├── imv/                        # Image viewer
├── kitty/
│   ├── kitty.conf              # GPU-accelerated terminal
│   └── mocha.conf              # Catppuccin Mocha theme
├── rofi/
│   └── config.rasi             # App launcher (Catppuccin Mocha theme)
├── waybar/
│   ├── config                  # Status bar layout
│   └── style.css               # Status bar styling
├── Thunar/                     # File manager config
├── mimeapps.list               # Default app associations
└── starship.toml               # Shell prompt
```

## Key Bindings (SUPER)

| Binding | Action |
|---|---|
| `Q` | Terminal (Kitty) |
| `R` | App launcher (Rofi) |
| `E` | File manager (Thunar) |
| `C` | Kill active window |
| `V` | Toggle floating |
| `L` | Lock screen (hyprlock) |
| `M` | Exit Hyprland |
| `SHIFT+M` | Logout menu (wlogout) |
| `H` | Clipboard history (cliphist + Rofi) |
| `W` | Enter resize mode (arrow keys to resize, `ESC`/`ENTER` to exit) |
| `SHIFT+B` | Reload Waybar |
| `1-0` | Switch workspaces |
| `TAB` | Toggle between last two workspaces |
| `SHIFT+left/right` | Move active window to prev/next workspace |
| `SHIFT+1-0` | Move active window to workspace |
| `Arrow keys` | Move focus |
| `SHIFT+hjkl` | Move windows |
| `G` | Toggle window group |
| `[` / `]` | Cycle group tabs |
| `CTRL+G` / `ALT+G` | Move window out of / into group |
| `ALT+TAB` | Window switcher (Rofi, all workspaces) |
| `Print` | Screenshot to file |
| `SUPER+Print` | Screenshot selection to clipboard |
| `SUPER+SHIFT+Print` | Screenshot selection to file |

## Changing the Wallpaper

Edit `.config/hypr/hyprpaper.conf` and update the `path`:

```ini
wallpaper {
    monitor =
    path = /home/victor/Pictures/your-image.jpg
    fit_mode = cover
}
```

Then reload: `pkill hyprpaper; hyprpaper &`

- Supported formats: PNG, JPG, JXL, WebP
- `fit_mode` options: `cover` (default), `contain`, `tile`, `fill`
- For a different wallpaper per monitor, add multiple `wallpaper {}` blocks with specific `monitor = eDP-1` etc., and keep one with `monitor =` (empty) as a fallback

To also update the SDDM login screen wallpaper, run `scripts/setup-sddm.sh` (with `sudo`) after changing the path there too.

## Bootstrap

On a fresh machine, clone this repository to `~/dotfiles` and run the install script:

```bash
git clone <repo-url> ~/dotfiles
~/dotfiles/install.sh
```

`install.sh` creates all symlinks (`~/.config/*`, `~/.zshrc`, `~/.gnupg/gpg-agent.conf`), backing up any existing file or directory with a timestamped suffix before replacing it. It is safe to re-run.

On a fresh openSUSE Tumbleweed install, the dotfiles bootstrap is handled automatically by the [opensuse-setup](https://github.com/engineervix/opensuse-setup) script as part of its final phase.

## Setup Notes

- **OS:** openSUSE Tumbleweed
- **Keyboard Layout:** en-gb (`gb`)
- **Login Manager:** SDDM (auto-login disabled)

*Refer to POST_SETUP.md for full details on the configuration architecture.*
