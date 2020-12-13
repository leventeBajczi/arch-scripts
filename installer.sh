#!/bin/bash
set -e

trap 'echo "\"${last_command}\" command failed with exit code $?."' EXIT

#ROOT=/dev/sda2
#BOOT=/dev/sda1
#HOME=/dev/sda3
#SWAP=/dev/sda4

ROOTMKFS="mkfs.xfs -f"
BOOTMKFS="mkfs.vfat"
HOMEMKFS="mkfs.xfs -f"

$ROOTMKFS $ROOT
mount $ROOT /mnt

$BOOTMKFS $BOOT
mkdir /mnt/boot -p
mount $BOOT /mnt/boot

if [ -z "$HOME" ]
then
    echo "No home"
else
    $HOMEMKFS $HOME
    mkdir /mnt/home =p
    mount $HOME /mnt/home
fi

if [ -z "$SWAP" ]
then
    echo "No swap"
else
    mkswap $SWAP
    swapon $SWAP
fi


HOME=$PWD reflector --verbose --latest 10 --sort rate --save /etc/pacman.d/mirrorlist
printf "[multilib]\nInclude = /etc/pacman.d/mirrorlist" >> /etc/pacman.conf

pacstrap /mnt - < pkglist.txt

cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist
cp aurpackages.txt /mnt/tmp/aurpackages.txt
#cp postinstall.sh /mnt/tmp/postinstall.sh
genfstab -U /mnt > /mnt/etc/fstab

arch-chroot /mnt postinstall.sh $BOOT

#reboot
