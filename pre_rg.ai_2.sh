#!/bin/bash

ln -sf /usr/share/zoneinfo/Europe/Bucharest /etc/localtime

hwclock --systohc --utc

echo "LANG=en_US.UTF-8" >> /etc/locale.conf
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "ro_RO.UTF-8 UTF-8" >> /etc/locale.gen
echo "en_US ISO-8859-1" >> /etc/locale.gen
echo "ro_RO ISO-8859-2" >> /etc/locale.gen
locale-gen

echo "KEYMAP=ro" >> /etc/vconsole.conf
echo "rg" >> /etc/hostname
echo "127.0.0.1       localhost" >> /etc/hosts
echo "::1             localhost" >> /etc/hosts
echo "127.0.1.1       rg.localdomain  rg" >> /etc/hosts

pacman -S --noconfirm --needed dialog sudo zsh os-prober

pacman -S --noconfirm --needed ifplugd wpa_supplicant

pacman --noconfirm --needed -S wireless_tools
#pacman --noconfirm --needed -S networkmanager
#pacman --noconfirm --needed -S network-manager-applet
pacman --noconfirm --needed -S gnome-keyring

#systemctl enable NetworkManager.service

#systemctl enable wpa_supplicant.service

#gpasswd -a rg network

#ip link set down lo
#ip link set down enp4s0f1
#ip link set down wlp3s0

#systemctl start wpa_supplicant.service

#systemctl disable dhcpcd.service
#systemctl disable dhcpcd@.service
#systemctl stop dhcpcd.service
#systemctl stop dhcpcd@.service

#systemctl start NetworkManager.service

#dialog --no-cancel --inputbox "Enter password for root." 10 65 2>rootpasswd

#cat <<EOF | passwd
#	${rootpasswd}
#	${rootpasswd}
#EOF

pacman --noconfirm --needed -S grub && grub-install --target=i386-pc --recheck /dev/sda && grub-mkconfig -o /boot/grub/grub.cfg

useradd -m -G wheel -s /usr/bin/zsh raulgavris
chsh -s /usr/bin/zsh

pacman -Sy --noconfirm
pacman -Su --noconfirm

dialog --title "Install rg.ai" --yesno "Would you like to go on and install rg.ai?"  5 50 && bash rg.ai.py

dialog --defaultno --title "Finally, here\! All installed\!" --yesno "Reboot computer?"  5 30 && reboot
clear

echo "visudo -> %wheel ALL uncomment"
echo "passwd"
echo "passwd user"

echo "systemctl enable netctl-auto@wlp..."
echo "systemctl enable netctl-ifplugd@enp..."

#################################################################
# ln -sf /etc/profile ~/.profile # for startx to start everytime
# autostart systemd default session on tty1
# if [[ "$(tty)" == '/dev/tty1' ]]; then
#         exec startx
# fi
# .xinitrc
# #! /bin/bash
# exec i3
