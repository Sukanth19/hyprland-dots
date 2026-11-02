# hyprland-dots

My personal Hyprland config, built on top of **[end-4/dots-hyprland](https://github.com/end-4/dots-hyprland)** ("illogical-impulse").

## Credits

Almost everything here is the work of **[end-4](https://github.com/end-4)** and the contributors to
[dots-hyprland](https://github.com/end-4/dots-hyprland). I only made small personal tweaks.
If you like how it looks, go star the original repo.

- Base: `dots/.config/hypr` from end-4/dots-hyprland at commit
  [`d619ddcd`](https://github.com/end-4/dots-hyprland/tree/d619ddcd8264b6daecf98b50e2ddd19f61ad1ecd/dots/.config/hypr)
- License: GPL-3.0, same as upstream (see [LICENSE](LICENSE))

## What I changed

The history has two commits so the changes are easy to see:

1. `import end-4/dots-hyprland hypr config`: end-4's original files, unmodified
2. `my changes on top of end-4's config`: my edits

**[See the full diff on GitHub →](https://github.com/Sukanth19/hyprland-dots/compare/109730a0ed32ac89a4db26a82facc123fdbc2bbf...3cfbc3d466fd5fd3447ccbf555d4a4cdcd11e260)** (or run `git diff 109730a 3cfbc3d` locally)

Most of my changes live in `hypr/custom/`, which end-4's setup keeps for user overrides.

### Keybinds
| Key | Action |
|---|---|
| `Super + A` | Left sidebar, opens on the Media tab (swapped with `Super + N`) |
| `Super + N` | Right sidebar |
| `Super + .` | Emoji tab in the left sidebar (instead of the launcher's emoji search) |
| `` Super + ` `` | Drop-down scratchpad terminal (kitty, on a special workspace) |
| `Super + Shift + E` | Screenshot a region and annotate it in swappy |
| `Super + Scroll` | Workspace scroll direction inverted |

### Window rules
- Spotify always opens on workspace 5
- Obsidian always opens on workspace 4, slightly transparent (0.96)
- Scratchpad terminal: floating, centered, 70% × 60% of the monitor

### Other
- Cursor: Bibata-Crosshair, size 24
- `udiskie` automounts USB drives on startup
- Colors (`hyprland/colors.lua`, `hyprlock/colors.conf`) are matugen-generated from my wallpaper
- Custom hyprlock background image

### Scripts
- `hypr/custom/scripts/scratchterm.sh`: starts or toggles the scratchpad terminal
- `hypr/custom/scripts/snip_annotate.sh`: `slurp` + `grim` + `swappy`

## Usage

Install end-4's dots first by following [their instructions](https://github.com/end-4/dots-hyprland).
Then copy over the parts you want, usually just `hypr/custom/`:

```bash
cp -r hypr/custom ~/.config/hypr/
```

Extra packages my changes use: `kitty`, `jq`, `swappy`, `grim`, `slurp`, `udiskie`, `bibata-cursor-theme`.
