# Purpose

System installation framework. Scripts under `install/` are sourced during `install.sh` to set up Omarchy on a fresh Arch system. For unattended Arch installs before Omarchy, see `archinstall/` and `arch-setup.sh`.

# Ownership

- Installation stages: `preflight/`, `packaging/`, `config/`, `login/`, `post-install/`, `first-run/`
- Helper infrastructure: `helpers/chroot.sh`, `helpers/logging.sh`, `helpers/errors.sh`, `helpers/presentation.sh`
- Package lists: `omarchy-base.packages`, `omarchy-other.packages`
- Hardware-specific configuration under `config/hardware/`
- Custom package scripts under `packaging/` (minio, antigravity, kimchi, nvim, sublime-merge, npm, tuis)
- Web app packaging removed in favor of runtime webapp launchers

# Local Contracts

- Install entry points (`install.sh`, `boot.sh`) use `#!/bin/bash`
- Scripts under `install/` are sourced via `run_logged` and intentionally omit shebangs
- Stage files follow the pattern: `install/*/all.sh` lists scripts in execution order
- Leaf scripts are sourced by `run_logged $OMARCHY_INSTALL/path/to/script.sh`
- Avoid `exit` in sourced scripts unless intentionally aborting the install
- Use `$OMARCHY_INSTALL` and `$OMARCHY_PATH` instead of hard-coded Omarchy paths
- Keep hardware-specific logic under `install/config/hardware/`

# Work Guidance

## Stage ordering

Install stages run in order: `preflight` → `packaging` → `config` → `login` → `post-install`. `first-run/` scripts run on first boot after install.

## Packaging layout

`install/packaging/all.sh` lists scripts in execution order:
- `base.sh` — core packages from `omarchy-base.packages`
- `fonts.sh`, `nvim.sh`, `icons.sh`, `tuis.sh`, `npm.sh`
- Custom tools: `minio-client.sh`, `antigravity.sh`, `kimchi.sh`, `sublime-merge.sh`
- Hardware: `asus-rog.sh`, `framework16.sh`, `dell-xps-touchpad-haptics.sh`, `surface.sh`

Web apps are no longer installed via `webapps.sh`; use runtime launchers instead.

## Adding a new config script

1. Create the script in `install/config/` (or `install/config/hardware/<vendor>/` for hardware-specific)
2. Add `run_logged $OMARCHY_INSTALL/config/<script>.sh` to `install/config/all.sh`
3. For hardware-specific scripts, add the `run_logged` call at the appropriate vendor section

## Package lists

- `omarchy-base.packages` - core packages installed during packaging stage
- `omarchy-other.packages` - optional packages that can be installed later

## Hardware configs

- `install/config/hardware/` - generic hardware scripts (bluetooth, nvidia, etc.)
- `install/config/hardware/<vendor>/` - vendor-specific scripts (apple, asus, framework, intel, lenovo)
- Hardware detection is done via `omarchy-hw-*` commands (from `bin/`)

## Exceptions

Raw `command -v`, `pacman`, and `pacman-key` are acceptable in `helpers/`, `preflight/`, and `packaging/` scripts where helper commands may not be available yet.

# Verification

Installation is verified by running `install.sh` on a fresh Arch system. There is no automated test suite for install scripts.