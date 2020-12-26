1. Partition the disks to have a root, home and boot partition
2. Fill installer.sh with the paths of these partitions
3. Fill postinstall.sh with passwords and users
4. Run installer.sh


Necessary packages: base base-devel git grub linux efibootmgr networkmanager sddm bluetooth

Remove libvirtd from postinst if not needed
