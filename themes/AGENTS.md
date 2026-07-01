# Purpose

Theme color definitions, backgrounds, and per-app overrides. Themes are managed by `omarchy-theme-*` commands.

# Ownership

- Theme directory structure and naming
- `colors.toml` format
- Background images and preview assets
- Per-app overrides (neovim, vscode, btop, hyprland, hyprlock, waybar, swayosd, etc.)

# Work Guidance

## Theme structure

```
themes/<theme-name>/
├── colors.toml          # accent, background, foreground, color0-15
├── backgrounds/         # wallpaper images
├── preview.png          # theme preview for switcher
├── icons.theme          # icon theme selection
├── btop.theme           # btop color overrides
├── neovim.lua           # neovim color scheme
├── vscode.json          # VS Code color theme
├── hyprland.lua         # optional hyprland overrides
├── hyprlock.conf        # optional hyprlock overrides
├── waybar.css           # optional waybar overrides
├── swayosd.css          # optional swayosd overrides
├── light.mode           # empty file marks a light theme
└── unlock.png           # lockscreen background
```

## Adding a theme

1. Create `themes/<name>/colors.toml` with accent, background, foreground, and color0-15
2. Add at least one background image in `backgrounds/`
3. Add `preview.png` and `icons.theme`
4. Add per-app overrides as needed
5. Run `omarchy-theme-install <name>` to install

## Template system

`default/themed/*.tpl` templates use `{{ variable }}` placeholders for theme colors. `omarchy-theme-set-templates` renders them with the current theme's colors.

# Verification

```bash
omarchy-theme-list           # verify theme appears
omarchy-theme-set <name>     # apply and verify visually
omarchy-theme-switcher       # test theme switcher UI
```