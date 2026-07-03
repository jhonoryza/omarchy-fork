#!/bin/bash

# arch-setup.sh
# Jalankan dari Arch Linux live USB sebagai root
# Setup disk, install base system, Limine bootloader, user non-root
# Setelah selesai: reboot, login sebagai user, lalu jalankan arch-firstboot.sh

set -eEo pipefail

# ── Colors ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GRN='\033[0;32m'
YEL='\033[1;33m'
BLU='\033[0;34m'
NC='\033[0m'

info()    { echo -e "${BLU}[INFO]${NC} $*"; }
success() { echo -e "${GRN}[OK]${NC}   $*"; }
warn()    { echo -e "${YEL}[WARN]${NC} $*"; }
die()     { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }

# ── Root check ───────────────────────────────────────────────────────────────
(( EUID == 0 )) || die "Script harus dijalankan sebagai root dari live USB"

# ── Architecture check ───────────────────────────────────────────────────────
[[ $(uname -m) == "x86_64" ]] || die "Hanya mendukung x86_64"

# ── Secure Boot check ────────────────────────────────────────────────────────
if bootctl status 2>/dev/null | grep -q 'Secure Boot: enabled'; then
  die "Secure Boot harus dimatikan di BIOS sebelum melanjutkan"
fi

echo ""
echo -e "${GRN}╔══════════════════════════════════════════════╗${NC}"
echo -e "${GRN}║      Arch Linux Setup untuk Omarchy          ║${NC}"
echo -e "${GRN}╚══════════════════════════════════════════════╝${NC}"
echo ""

# ── Deteksi boot mode ────────────────────────────────────────────────────────
if [[ -d /sys/firmware/efi/efivars ]]; then
  BOOT_MODE="uefi"
  info "Boot mode terdeteksi: UEFI"
else
  BOOT_MODE="bios"
  info "Boot mode terdeteksi: BIOS Legacy"
fi

echo ""
read -rp "Konfirmasi boot mode [$BOOT_MODE] (tekan Enter untuk lanjut atau ketik 'uefi'/'bios'): " input_boot
[[ -n $input_boot ]] && BOOT_MODE="$input_boot"
[[ $BOOT_MODE == "uefi" || $BOOT_MODE == "bios" ]] || die "Boot mode tidak valid: $BOOT_MODE"
success "Boot mode: $BOOT_MODE"

# ── Pilih disk ───────────────────────────────────────────────────────────────
echo ""
info "Disk yang tersedia:"
lsblk -dpno NAME,SIZE,MODEL | grep -v loop
echo ""
read -rp "Target disk untuk install (default: /dev/sda): " TARGET_DISK
TARGET_DISK="${TARGET_DISK:-/dev/sda}"

[[ -b $TARGET_DISK ]] || die "Disk $TARGET_DISK tidak ditemukan"

echo ""
warn "PERINGATAN: Semua data di $TARGET_DISK akan DIHAPUS!"
warn "Disk: $TARGET_DISK ($(lsblk -dno SIZE "$TARGET_DISK"))"
echo ""
read -rp "Ketik 'ya' untuk konfirmasi: " confirm
[[ $confirm == "ya" ]] || die "Dibatalkan oleh user"

# ── Input username & password ────────────────────────────────────────────────
echo ""
while true; do
  read -rp "Username (non-root): " USERNAME
  [[ $USERNAME =~ ^[a-z][a-z0-9_-]*$ ]] && break
  warn "Username harus huruf kecil, dimulai dengan huruf, boleh angka/underscore/dash"
done

while true; do
  read -rsp "Password untuk $USERNAME: " USER_PASS; echo
  read -rsp "Konfirmasi password: " USER_PASS2; echo
  [[ $USER_PASS == "$USER_PASS2" ]] && break
  warn "Password tidak cocok, coba lagi"
done

while true; do
  read -rsp "Password root: " ROOT_PASS; echo
  read -rsp "Konfirmasi password root: " ROOT_PASS2; echo
  [[ $ROOT_PASS == "$ROOT_PASS2" ]] && break
  warn "Password tidak cocok, coba lagi"
done

read -rp "Hostname mesin ini (default: archlinux): " HOSTNAME
HOSTNAME="${HOSTNAME:-archlinux}"

read -rp "Timezone (default: Asia/Jakarta): " TIMEZONE
TIMEZONE="${TIMEZONE:-Asia/Jakarta}"

# ── Ringkasan ────────────────────────────────────────────────────────────────
echo ""
echo -e "${YEL}══ Ringkasan Konfigurasi ════════════════════════${NC}"
echo "  Disk       : $TARGET_DISK"
echo "  Boot mode  : $BOOT_MODE"
echo "  Username   : $USERNAME"
echo "  Hostname   : $HOSTNAME"
echo "  Timezone   : $TIMEZONE"
echo -e "${YEL}═════════════════════════════════════════════════${NC}"
echo ""
read -rp "Lanjutkan instalasi? (ya/tidak): " final_confirm
[[ $final_confirm == "ya" ]] || die "Dibatalkan"

# ── Partisi disk ─────────────────────────────────────────────────────────────
info "Membuat partisi di $TARGET_DISK ..."

if [[ $BOOT_MODE == "uefi" ]]; then
  # GPT: EFI (512M) + Btrfs root (sisa)
  parted -s "$TARGET_DISK" \
    mklabel gpt \
    mkpart ESP fat32 1MiB 513MiB \
    set 1 esp on \
    mkpart primary btrfs 513MiB 100%

  partprobe "$TARGET_DISK"
  udevadm settle

  # Tentukan nama partisi (nvme pakai p1/p2, sata pakai 1/2)
  if [[ $TARGET_DISK == *nvme* ]]; then
    EFI_PART="${TARGET_DISK}p1"
    ROOT_PART="${TARGET_DISK}p2"
  else
    EFI_PART="${TARGET_DISK}1"
    ROOT_PART="${TARGET_DISK}2"
  fi

  info "Format EFI partition ..."
  mkfs.fat -F32 "$EFI_PART"

else
  # MBR: BIOS boot (1M) + Btrfs root (sisa)
  parted -s "$TARGET_DISK" \
    mklabel msdos \
    mkpart primary btrfs 2MiB 100% \
    set 1 boot on

  partprobe "$TARGET_DISK"
  udevadm settle

  if [[ $TARGET_DISK == *nvme* ]]; then
    ROOT_PART="${TARGET_DISK}p1"
  else
    ROOT_PART="${TARGET_DISK}1"
  fi
fi

# ── Format & mount Btrfs ─────────────────────────────────────────────────────
info "Format Btrfs di $ROOT_PART ..."
mkfs.btrfs -f "$ROOT_PART"

info "Mount dan buat Btrfs subvolumes ..."
mount "$ROOT_PART" /mnt

btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@snapshots
btrfs subvolume create /mnt/@var_log

umount /mnt

BTRFS_OPTS="defaults,compress=zstd:1,discard=async,noatime"

mount -o "${BTRFS_OPTS},subvol=@" "$ROOT_PART" /mnt

mkdir -p /mnt/{home,.snapshots,var/log,boot}

mount -o "${BTRFS_OPTS},subvol=@home"      "$ROOT_PART" /mnt/home
mount -o "${BTRFS_OPTS},subvol=@snapshots" "$ROOT_PART" /mnt/.snapshots
mount -o "${BTRFS_OPTS},subvol=@var_log"   "$ROOT_PART" /mnt/var/log

if [[ $BOOT_MODE == "uefi" ]]; then
  mount "$EFI_PART" /mnt/boot
fi

success "Partisi selesai di-mount"

# ── Pacstrap ─────────────────────────────────────────────────────────────────
info "Update mirrorlist ..."
reflector --country Indonesia,Singapore --age 12 --sort rate --save /etc/pacman.d/mirrorlist 2>/dev/null \
  || warn "reflector gagal, pakai mirrorlist bawaan"

info "Install base system (ini butuh beberapa menit) ..."
pacstrap -K /mnt \
  base base-devel linux linux-headers linux-firmware \
  btrfs-progs \
  networkmanager \
  git openssh curl \
  sudo vim \
  gum \
  limine \
  efibootmgr \
  dosfstools \
  amd-ucode intel-ucode

success "Base system terinstall"

# ── fstab ────────────────────────────────────────────────────────────────────
info "Generate fstab ..."
genfstab -U /mnt >> /mnt/etc/fstab
success "fstab selesai"

# ── Chroot config ────────────────────────────────────────────────────────────
info "Konfigurasi sistem via arch-chroot ..."

arch-chroot /mnt /bin/bash -s "$TIMEZONE" "$HOSTNAME" "$USERNAME" "$USER_PASS" "$ROOT_PASS" "$BOOT_MODE" "$TARGET_DISK" "$ROOT_PART" "${EFI_PART:-}" << 'CHROOT'
TIMEZONE="$1"
HOSTNAME="$2"
USERNAME="$3"
USER_PASS="$4"
ROOT_PASS="$5"
BOOT_MODE="$6"
TARGET_DISK="$7"
ROOT_PART="$8"
EFI_PART="$9"

set -eEo pipefail

# Timezone
ln -sf "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime
hwclock --systohc

# Locale
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Hostname
echo "$HOSTNAME" > /etc/hostname
cat > /etc/hosts << EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOSTNAME.localdomain $HOSTNAME
EOF

# Root password
echo "root:$ROOT_PASS" | chpasswd

# User
useradd -m -G wheel,audio,video,input,storage,optical,network -s /bin/bash "$USERNAME"
echo "$USERNAME:$USER_PASS" | chpasswd

# Sudo (wheel group)
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
grep -q '^%wheel ALL=(ALL:ALL) ALL' /etc/sudoers || { echo "ERROR: sudoers wheel line tidak ditemukan" >&2; exit 1; }

# mkinitcpio dengan btrfs
grep -q '\bbtrfs\b' /etc/mkinitcpio.conf || \
  sed -i '/^MODULES=/ s/)$/ btrfs)/' /etc/mkinitcpio.conf
mkinitcpio -P

# Enable NetworkManager
systemctl enable NetworkManager

# Enable SSH
systemctl enable sshd

# ── Limine bootloader ──────────────────────────────────────────────────────
ROOT_UUID=$(blkid -s UUID -o value "$ROOT_PART")

# Set Btrfs default subvolume to @ so Limine can find kernel/initramfs without subvol hint
SUBVOL_ID=$(btrfs subvolume list / | awk '$NF == "@" {print $2}')
[[ -n $SUBVOL_ID ]] || { echo "ERROR: tidak bisa menemukan subvolume @" >&2; exit 1; }
btrfs subvolume set-default "$SUBVOL_ID" /

if [[ $BOOT_MODE == "uefi" ]]; then
  # ESP is mounted at /boot; kernel/initramfs are installed there by pacman
  # boot() in Limine refers to the ESP, so paths are relative to ESP root (no /boot/ prefix)
  mkdir -p /boot/EFI/BOOT
  cp /usr/share/limine/BOOTX64.EFI /boot/EFI/BOOT/BOOTX64.EFI

  cat > /boot/EFI/BOOT/limine.conf << EOF
timeout: 3
default_entry: 1

/Arch Linux
  protocol: linux
  kernel_path: boot():/vmlinuz-linux
  cmdline: root=UUID=$ROOT_UUID rw rootflags=subvol=@ quiet splash
  module_path: boot():/initramfs-linux.img
  module_path: boot():/intel-ucode.img
  module_path: boot():/amd-ucode.img

/Arch Linux (fallback)
  protocol: linux
  kernel_path: boot():/vmlinuz-linux
  cmdline: root=UUID=$ROOT_UUID rw rootflags=subvol=@
  module_path: boot():/initramfs-linux-fallback.img
EOF

  # Register UEFI boot entry
  efibootmgr --disk "$TARGET_DISK" --part 1 \
    --create --label "Limine" \
    --loader "\\EFI\\BOOT\\BOOTX64.EFI" 2>/dev/null || true
else
  # BIOS: Limine stage2 on MBR; config + kernel read from root Btrfs partition
  # Default subvolume is now @ so boot():/boot/vmlinuz-linux resolves correctly
  limine bios-install "$TARGET_DISK"
  cp /usr/share/limine/limine-bios.sys /boot/

  mkdir -p /boot/limine
  cat > /boot/limine/limine.conf << EOF
timeout: 3
default_entry: 1

/Arch Linux
  protocol: linux
  kernel_path: boot():/boot/vmlinuz-linux
  cmdline: root=UUID=$ROOT_UUID rw rootflags=subvol=@ quiet splash
  module_path: boot():/boot/initramfs-linux.img
  module_path: boot():/boot/intel-ucode.img
  module_path: boot():/boot/amd-ucode.img

/Arch Linux (fallback)
  protocol: linux
  kernel_path: boot():/boot/vmlinuz-linux
  cmdline: root=UUID=$ROOT_UUID rw rootflags=subvol=@
  module_path: boot():/boot/initramfs-linux-fallback.img
EOF
fi

echo "Chroot konfigurasi selesai"
CHROOT

success "Konfigurasi chroot selesai"

# ── Copy firstboot script ────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/arch-firstboot.sh" ]]; then
  cp "$SCRIPT_DIR/arch-firstboot.sh" "/mnt/home/$USERNAME/arch-firstboot.sh"
  chmod +x "/mnt/home/$USERNAME/arch-firstboot.sh"
  success "arch-firstboot.sh disalin ke /home/$USERNAME/"
fi

# ── Selesai ──────────────────────────────────────────────────────────────────
echo ""
echo -e "${GRN}══════════════════════════════════════════════════${NC}"
echo -e "${GRN}  Instalasi base selesai!${NC}"
echo -e "${GRN}══════════════════════════════════════════════════${NC}"
echo ""
echo "Langkah selanjutnya:"
echo "  1. umount -R /mnt"
echo "  2. reboot"
echo "  3. Login sebagai: $USERNAME"
echo "  4. Jalankan: bash ~/arch-firstboot.sh"
echo ""
