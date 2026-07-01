# Purpose

Omarchy is a beautiful, modern & opinionated Linux distribution (Arch-based with Hyprland) by DHH. This repository contains the full system configuration, CLI tooling, installation framework, themes, and migration scripts.

# Ownership

Project-wide coding conventions, config structure, helper command policy, and visual change verification. Everything under this root.

# Local Contracts

## Style

- Two spaces for indentation, no tabs
- Use bash 5 conditionals: use `[[ ]]` for string/file tests and `(( ))` for numeric tests
- In `[[ ]]`, don't quote variables, but do quote string literals when comparing values (e.g., `[[ $branch == "dev" ]]`)
- Prefer `(( ))` over numeric operators inside `[[ ]]` (e.g., `(( count < 50 ))`, not `[[ $count -lt 50 ]]`)
- For strings/paths with spaces, quote them instead of escaping spaces with `\ ` (e.g., `"$APP_DIR/Disk Usage.desktop"`, not `$APP_DIR/Disk\ Usage.desktop`)
- Shebangs must use `#!/bin/bash` consistently (never `#!/usr/bin/env bash`)
- Scripts under `install/` and `migrations/` may be sourced and intentionally omit shebangs

## Helper Commands

Use these instead of raw shell commands:

- `omarchy-cmd-missing` / `omarchy-cmd-present` - check for commands
- `omarchy-pkg-missing` / `omarchy-pkg-present` - check for packages
- `omarchy-pkg-add` - install packages (handles both pacman and AUR)
- `omarchy-pkg-drop` - remove packages; use this instead of raw `pacman -R*`
- `omarchy-notification-send` - send desktop notifications; do not call `notify-send` directly
- `omarchy-hw-asus-rog` - detect ASUS ROG hardware (and similar `hw-*` commands)

Exceptions are allowed for bootstrap, preflight, migration, and package-helper scripts where the helper may not be available yet, where the helper itself is being implemented, or where direct package-manager behavior is required.

## Config Structure

- `config/` - default configs copied to `~/.config/`
- `default/themed/*.tpl` - templates with `{{ variable }}` placeholders for theme colors
- `themes/*/colors.toml` - theme color definitions (accent, background, foreground, color0-15)

## Refresh Pattern

To copy a default config to user config with automatic backup:

```bash
omarchy-refresh-config hypr/hyprlock.conf
```

This copies `~/.local/share/omarchy/config/hypr/hyprlock.conf` to `~/.config/hypr/hyprlock.conf`.

# Work Guidance

## Visual Changes

When making visual changes, such as Waybar styles or desktop appearance, always take and analyze a screenshot after applying the change to verify the result. Use `omarchy capture screenshot fullscreen save` for fullscreen screenshots.

For interactive UI work, use `wtype` to simulate keyboard input when available. Example: start the UI in the background, wait briefly for focus, then run `wtype -k Right -k Return` to exercise keyboard selection and confirm the resulting command output or state change. Prefer this over manual-only verification when a UI returns a selected value or changes a symlink/config.

When testing layer-shell UI, capture the reference and candidate states as separate screenshots, then compare them visually before further edits. If a launched UI would otherwise remain open, keep track of its PID and stop it after the screenshot; avoid broad process kills unless checking with `ps` first.

# Verification

```bash
bash test/omarchy-cli-test.sh
```

# Child DOX Index

- [bin/](bin/AGENTS.md) — CLI commands, dispatcher, metadata, and GROUP_DESCRIPTIONS
- [install/](install/AGENTS.md) — Installation framework, stages, sourcing, and hardware configs
- [migrations/](migrations/AGENTS.md) — User migration scripts and format
- [themes/](themes/AGENTS.md) — Theme color definitions, backgrounds, and per-app overrides