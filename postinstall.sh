#!/bin/bash

set -e

trap 'echo "\"${last_command}\" command failed with exit code $?."' EXIT

#ROOTPASSWD=
#USERNAME=
#USERPASSWD=

printf "$ROOTPASSWD\n$ROOTPASSWD" | passwd

useradd -m -G wheel $USERNAME
printf "$USERPASSWD\n$USERPASSWD" | passwd $USERNAME

echo "%wheel ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

echo $USERPASSWD | sudo -u $USERNAME chsh -s /usr/bin/zsh

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

git clone https://aur.archlinux.org/paru.git /tmp/paru && cd /tmp/paru && chown $USERNAME . -R && sudo -u $USERNAME makepkg -si --noconfirm

sudo -u $USERNAME paru -S --noconfirm - < /postinst/aurpackages.txt


exit
