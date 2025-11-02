#!/bin/bash
set -e

trap 'echo "\"${last_command}\" command failed with exit code $?."' EXIT

# Example device setup (adjust these before running)
# ROOT=/dev/nvme0n1
# BOOT=/dev/nvme0n1
# SWAP=/dev/nvme0n1
# DEV=/dev/nvme0n1

ROOTMKFS="mkfs.btrfs -f -L archroot"
BOOTMKFS="mkfs.vfat -F32"

# --- Format and prepare root Btrfs filesystem ---
$ROOTMKFS $ROOT

# Mount temporarily to create subvolumes
mount $ROOT /mnt

# Create subvolumes
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@log
btrfs subvolume create /mnt/@cache
btrfs subvolume create /mnt/@snapshots

# Unmount temporary mount
umount /mnt

# --- Mount subvolumes with recommended options ---
mount -o noatime,compress=zstd,space_cache=v2,discard=async,subvol=@ $ROOT /mnt

mkdir -p /mnt/{boot,home,var/log,var/cache/pacman/pkg,.snapshots}

mount -o noatime,compress=zstd,space_cache=v2,discard=async,subvol=@home $ROOT /mnt/home
mount -o noatime,compress=zstd,space_cache=v2,discard=async,subvol=@log $ROOT /mnt/var/log
mount -o noatime,compress=zstd,space_cache=v2,discard=async,subvol=@cache $ROOT /mnt/var/cache/pacman/pkg
mount -o noatime,compress=zstd,space_cache=v2,discard=async,subvol=@snapshots $ROOT /mnt/.snapshots

# --- Mount EFI partition ---
$BOOTMKFS $BOOT
mount $BOOT /mnt/boot

# --- Swap setup ---
if [ -z "$SWAP" ]; then
    echo "No swap"
else
    mkswap $SWAP
    swapon $SWAP
fi

# --- Mirrorlist & pacman setup ---
HOME=$PWD reflector --country 'Germany,France' --protocol https --latest 10 --sort rate --save /etc/pacman.d/mirrorlist

# --- Install base system ---
pacstrap /mnt - < pkglist.txt

# --- Copy post-install files ---
cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist
mkdir -p /mnt/postinst
cp aurpackages.txt /mnt/postinst/aurpackages.txt
cp postinstall.sh /mnt/postinst/postinstall.sh

# --- Generate fstab ---
genfstab -U /mnt > /mnt/etc/fstab

# --- Run postinstall inside chroot ---
arch-chroot /mnt /postinst/postinstall.sh $DEV

# Uncomment after testing
# reboot
