#!/bin/bash

# arch-firstboot.sh
# Jalankan setelah reboot pertama ke sistem Arch yang baru
# Login sebagai user non-root, lalu: bash ~/arch-firstboot.sh
#
# Script ini akan:
# 1. Cek koneksi internet
# 2. Clone repo omarchy-fork via HTTPS
# 3. Jalankan install.sh

set -eEo pipefail

RED='\033[0;31m'
GRN='\033[0;32m'
YEL='\033[1;33m'
BLU='\033[0;34m'
NC='\033[0m'

info()    { echo -e "${BLU}[INFO]${NC} $*"; }
success() { echo -e "${GRN}[OK]${NC}   $*"; }
warn()    { echo -e "${YEL}[WARN]${NC} $*"; }
die()     { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }

# ── Sanity checks ────────────────────────────────────────────────────────────
(( EUID != 0 )) || die "Jangan jalankan sebagai root. Login sebagai user biasa dulu."
[[ $(uname -m) == "x86_64" ]] || die "Hanya mendukung x86_64"
[[ -f /etc/arch-release ]] || die "Harus dijalankan di Arch Linux"

echo ""
echo -e "${GRN}╔══════════════════════════════════════════════╗${NC}"
echo -e "${GRN}║    Omarchy First Boot Setup                  ║${NC}"
echo -e "${GRN}╚══════════════════════════════════════════════╝${NC}"
echo ""

# ── Cek internet ─────────────────────────────────────────────────────────────
info "Cek koneksi internet ..."
if ! curl --silent --max-time 5 -o /dev/null https://archlinux.org; then
  warn "Tidak ada koneksi internet. Coba connect dulu:"
  echo "  nmcli device wifi connect <SSID> password <password>"
  echo "  atau: nmtui"
  echo ""
  read -rp "Tekan Enter setelah internet tersambung ..."
  curl --silent --max-time 10 -o /dev/null https://archlinux.org || die "Masih tidak ada internet"
fi
success "Internet OK"

# ── Clone repo ───────────────────────────────────────────────────────────────
echo ""
info "Clone repo omarchy-fork ke ~/.local/share/omarchy ..."

OMARCHY_PATH="$HOME/.local/share/omarchy"

if [[ -d $OMARCHY_PATH ]]; then
  warn "Directory $OMARCHY_PATH sudah ada"
  read -rp "Hapus dan clone ulang? (y/n, default: y): " reclone
  reclone="${reclone:-y}"
  if [[ $reclone == "y" ]]; then
    rm -rf "$OMARCHY_PATH"
  else
    info "Pakai repo yang sudah ada"
  fi
fi

if [[ ! -d $OMARCHY_PATH ]]; then
  mkdir -p "$(dirname "$OMARCHY_PATH")"
  git clone https://github.com/jhonoryza/omarchy-fork.git "$OMARCHY_PATH"
  success "Repo berhasil di-clone ke $OMARCHY_PATH"
fi

# ── Jalankan install.sh ──────────────────────────────────────────────────────
echo ""
echo -e "${YEL}══════════════════════════════════════════════════${NC}"
echo -e "${YEL}  Siap menjalankan install.sh!${NC}"
echo -e "${YEL}══════════════════════════════════════════════════${NC}"
echo ""
echo "Ini akan menginstall Omarchy (Hyprland + semua paket)."
echo "Proses ini bisa memakan waktu 20-60 menit tergantung koneksi."
echo ""
read -rp "Jalankan install.sh sekarang? (ya/tidak): " run_install
[[ $run_install == "ya" ]] || { info "Jalankan manual: bash ~/.local/share/omarchy/install.sh"; exit 0; }

info "Menjalankan install.sh ..."
bash "$OMARCHY_PATH/install.sh"
