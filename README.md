# Omarchy Fork

Omarchy is a beautiful, modern & opinionated Linux distribution by DHH, customized for personal use.

Based on [omarchy.org](https://omarchy.org).

## Installation

### Requirements

- Vanilla Arch Linux (x86_64)
- Secure Boot disabled in BIOS
- Limine bootloader
- Btrfs root filesystem (`/`)
- Non-root user

### Step 1 — Boot Arch live USB, run setup script

```bash
curl -fsSL https://raw.githubusercontent.com/jhonoryza/omarchy-fork/main/arch-setup.sh -o arch-setup.sh
curl -fsSL https://raw.githubusercontent.com/jhonoryza/omarchy-fork/main/arch-firstboot.sh -o arch-firstboot.sh
bash arch-setup.sh
```

`arch-setup.sh` will:
- Detect UEFI or BIOS Legacy boot mode
- Partition disk with Btrfs filesystem
- Install base Arch system via pacstrap
- Install and configure Limine bootloader
- Create non-root user with sudo access
- Copy `arch-firstboot.sh` to the new user's home directory

When done, unmount and reboot:

```bash
umount -R /mnt
reboot
```

### Step 2 — First boot, run Omarchy installer

Login as the non-root user you created, then:

```bash
bash ~/arch-firstboot.sh
```

`arch-firstboot.sh` will:
- Check internet connection (WiFi setup via `nmtui` if needed)
- Clone this repo to `~/.local/share/omarchy` via HTTPS
- Run `install.sh` to install Omarchy (Hyprland + all packages)

The install process takes 20-60 minutes depending on connection speed.

### Manual install (if you already have base Arch ready)

```bash
git clone https://github.com/jhonoryza/omarchy-fork.git ~/.local/share/omarchy
bash ~/.local/share/omarchy/install.sh
```

## License

Omarchy is released under the [MIT License](https://opensource.org/licenses/MIT).
