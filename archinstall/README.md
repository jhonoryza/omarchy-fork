# Archinstall Config

Kustomisasi config untuk [archinstall](https://github.com/archlinux/archinstall) sesuai preferensi pribadi.

## File

- `config.json` — konfigurasi disk, paket, locale, timezone, bootloader, dll
- `creds.json` — user dan root password (dalam hash, bukan plain text)

## Cara pakai

### Dari Arch live USB

```bash
# Download archinstall
pacman -Sy --noconfirm python archinstall

# Salin config
mkdir -p /root/archinstall
cp /path/to/this/repo/archinstall/config.json /root/archinstall/
cp /path/to/this/repo/archinstall/creds.json /root/archinstall/

# Edit creds.json — ganti hash dengan password hash yang benar
# Generate hash dengan: python3 -c "import crypt; print(crypt.crypt('password', crypt.mksalt(crypt.METHOD_SHA512)))"
nano /root/archinstall/creds.json

# Jalankan archinstall dengan config
archinstall --config /root/archinstall/config.json --creds /root/archinstall/creds.json
```

### Via curl langsung

```bash
# Download config
curl -fsSL https://raw.githubusercontent.com/jhonoryza/omarchy-fork/main/archinstall/config.json -o /root/archinstall/config.json
curl -fsSL https://raw.githubusercontent.com/jhonoryza/omarchy-fork/main/archinstall/creds.json -o /root/archinstall/creds.json

# Edit creds dan jalankan
archinstall --config /root/archinstall/config.json --creds /root/archinstall/creds.json
```

## Preferensi

- **Bootloader**: Limine (UEFI)
- **Disk**: 512MB EFI + sisa Btrfs root
- **Desktop**: Hyprland (via manual setup setelah archinstall)
- **Browser**: Brave (AUR)
- **Media**: VLC
- **Editor**: Neovim (dengan config jhonoryza/nvim) + Sublime Text + Sublime Merge
- **Terminal**: Ghostty + Foot
- **Tools**: tmux, btop, fastfetch, starship, lazydocker, cmake, make, cups
- **Audio**: PipeWire
- **Timezone**: Asia/Jakarta
- **Locale**: en_US.UTF-8

### Custom commands (post-install)

Setelah pacman + AUR selesai, custom_commands otomatis menjalankan:

```bash
# 1. Clone nvim config
git clone https://github.com/jhonoryza/nvim.git /home/fajar/.config/nvim

# 2. Install antigravity CLI
curl -fsSL https://antigravity.google/cli/install.sh | bash

# 3. Install kimchi CLI
curl -fsSL https://github.com/getkimchi/kimchi/releases/latest/download/install.sh | bash

# 4. Install MinIO client
curl -fsSL https://dl.min.io/client/mc/release/linux-amd64/mc -o /usr/local/bin/mc

# 5. Install npm global packages
npm install -g opencode-ai playwright wrangler netlify-cli @mimo-ai/cli cline freebuff
```

## Catatan

- `config.json` adalah template — sesuaikan `device` di `disk_config` dengan disk target
- `creds.json` menggunakan SHA512 hash, bukan plain text
- `brave-bin`, `sublime-text-4`, `sublime-merge`, `ghostty` adalah paket AUR — archinstall akan build otomatis
- Custom commands dijalankan sebagai root setelah base install; nvim config di-`chown` ke user `fajar`
- Setelah archinstall selesai, jalankan manual setup untuk Hyprland dan konfigurasi tema tambahan
