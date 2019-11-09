#!/bin/bash

# Made by Raul Gavris <http://raulgavris.com>

dialog --defaultno --title "Arch Linux install\!" --yesno "Do not forget about mirrorslist vim /etc/pacman.d/mirrorlist"  7 50 || exit

pacman -Sy --noconfirm dialog || { echo "Error at script start: Are you sure you're running this as the root user? Are you sure you have an internet connection?"; exit; }

dialog --defaultno --title "Arch Linux install\!" --yesno "Are you sure you want to wipe out your entire hard disk and install Arch from zero?"  7 50 || exit

dialog --no-cancel --inputbox "Enter partition size in gb, separated by space (swap & root)." 10 65 2>psize

IFS=' ' read -ra SIZE <<< $(cat psize)

re='^[0-9]+$'
if ! [ ${#SIZE[@]} -eq 2 ] || ! [[ ${SIZE[0]} =~ $re ]] || ! [[ ${SIZE[1]} =~ $re ]] ; then
    SIZE=(12 25);
fi

# Windows -> command prompt installation -> BootRec.exe /FixMbr -> overwrites(deletes) grub
# ls /usr/share/kbd/keymaps/**/*.map.gz # checks for keyboars layouts
# shift + pgup / pgdown for navigation
loadkeys ro
# ls /sys/firmware/efi/efivars # checks if it is a uefi installation, this should be none
# wifi-menu # ping google.com
timedatectl set-ntp true
timedatectl status

# fdiks -l -> lsblk
# BOOT -> 200M
# SWAP -> (150/100)G of RAM
# ROOT -> 30G
# HOME -> the difference

# cat <<EOF | fdisk /dev/sda
# d
#
# d
#
# d
#
# d
#
# w
# EOF
#
# cat <<EOF | fdisk /dev/sda
# n
# p
#
#
# +200M
# a
# n
# p
#
#
# +${SIZE[0]}G
# n
# p
#
#
# +${SIZE[1]}G
# n
# p
#
#
# w
# EOF
#
# yes | mkfs.ext4 /dev/sda1
# yes | mkfs.ext4 /dev/sda3
# yes | mkfs.ext4 /dev/sda4
# mkswap /dev/sda2
# swapon /dev/sda2
# mount /dev/sda3 /mnt
# mkdir /mnt/boot
# mkdir /mnt/home
# mount /dev/sda1 /mnt/boot
# mount /dev/sda4 /mnt/home


cat <<EOF fdisk /dev/nvme0n1
d

d

d

d

w
EOF

cat <<EOF fdisk /dev/nvme0n1
n
p


+200M
a
n
p


+${SIZE[0]}G
n
p


+${SIZE[1]}G
n
p


w
EOF

yes | mkfs.fat -F32 /dev/nvme0n1p1
yes | mkfs.ext4 /dev/nvme0n1p3
yes | mkfs.ext4 /dev/nvme0n1p4
mkswap /dev/nvme0n1p2
swapon /dev/nvme0n1p2
mount /dev/nvme0n1p3 /mnt
mkdir /mnt/home
mout /nvme0n1p4 /mnt/home



pacman -Sy --noconfirm archlinux-keyring

echo "LANG=en_US.UTF-8" >> /etc/locale.conf
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "ro_RO.UTF-8 UTF-8" >> /etc/locale.gen
echo "en_US ISO-8859-1" >> /etc/locale.gen
echo "ro_RO ISO-8859-2" >> /etc/locale.gen
locale-gen

pacstrap /mnt base base-devel linux linux-firmware vim dialog git

genfstab -U /mnt >> /mnt/etc/fstab # again after mounting the boot partition and clean fstab

#cat <<EOF > /mnt rg.ai2.sh
#
#EOF

# cp rg.ai2.sh /mnt

# arch-chroot /mnt bash rg.ai2.sh

# rm rg.ai2.sh /mnt/rg.ai2.sh

cp test.sh /mnt
