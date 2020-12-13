#!/bin/bash

set -e

trap 'echo "\"${last_command}\" command failed with exit code $?."' EXIT

#ROOTPASSWD=
#USERNAME=
#USERPASSWD=

echo $ROOTPASSWD | passwd

useradd -m -G wheel $USERNAME
echo $USERPASSWD | passwd levente

echo "%wheel ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

echo $USERPASSWD | sudo -u levente chsh -s /usr/bin/zsh

systemctl enable NetworkManager
systemctl enable bluetooth
systemctl enable libvirtd
systemctl enable sddm

if [ -z "$1" ]
then
    echo "Device not set!"
else
    grub-install $1 --efi-directory=/boot
    grub-mkconfig -o /boot/grub/grub.cfg
fi

pacman -Sy

git clone https://aur.archlinux.org/paru.git /tmp/paru && cd /tmp/paru && sudo -u levente makepkg -si --noconfirm

paru -S --noconfirm - < /postinst/aurpackages.txt


exit
