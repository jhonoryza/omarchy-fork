# Purpose

CLI command scripts and the `omarchy` dispatcher. Every `bin/omarchy-*` script is a user-facing or internal command, dispatched by `bin/omarchy`.

# Ownership

- Command naming (`omarchy-<prefix>-<name>`)
- Command metadata comments (`# omarchy:summary=...`, etc.)
- `GROUP_DESCRIPTIONS` in `bin/omarchy`
- Help text, argument parsing, and route registration
- New command creation and deletion

# Work Guidance

## Adding a command

1. Create `bin/omarchy-<prefix>-<name>` with `#!/bin/bash`
2. Add metadata in the first 80 lines:
   - `# omarchy:summary=...` (required for user-facing commands)
   - `# omarchy:group=...` (only when different from filename-derived prefix)
   - `# omarchy:args=...`
   - `# omarchy:examples=...` (separated by ` | `)
   - `# omarchy:aliases=...`
   - `# omarchy:requires-sudo=true` (when needed)
   - `# omarchy:hidden=true` (for internal-only commands)
3. When adding a new prefix, register it in `GROUP_DESCRIPTIONS` in `bin/omarchy`
4. After adding, run `bin/omarchy` commands to validate metadata parsing

## Style

- `#!/bin/bash` shebang, no `#!/usr/bin/env bash`
- Two-space indentation, no tabs
- Bash 5 conditionals: `[[ ]]` for strings, `(( ))` for numbers
- Quote strings with spaces, don't quote bare variables in `[[ ]]`
- Prefer helper commands (see root AGENTS.md) over raw `pacman`, `command -v`, etc.

## Helper commands

Use these instead of raw shell commands:
- `omarchy-cmd-missing` / `omarchy-cmd-present` for command checks
- `omarchy-pkg-missing` / `omarchy-pkg-present` / `omarchy-pkg-add` / `omarchy-pkg-drop` for package management
- `omarchy-notification-send` for desktop notifications
- `omarchy-hw-*` for hardware detection

# Verification

```bash
bash test/omarchy-cli-test.sh
```