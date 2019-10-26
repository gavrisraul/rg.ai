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

cat <<EOF | fdisk /dev/sda
d

d

d

d

w
EOF

cat <<EOF | fdisk /dev/sda
n
p


+200M
n
p


+${SIZE[0]}G
n
p


+${SIZE[1]}G
n
p


a
4
w
EOF

yes | mkfs.ext4 /dev/sda1
yes | mkfs.ext4 /dev/sda3
yes | mkfs.ext4 /dev/sda4
mkswap /dev/sda2
swapon /dev/sda2
mount /dev/sda3 /mnt
mkdir /mnt/boot
mkdir /mnt/home
mount /dev/sda1 /mnt/boot
mount /dev/sda4 /mnt/home

pacman -Sy --noconfirm archlinux-keyring

echo "LANG=en_US.UTF-8" >> /etc/locale.conf
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "ro_RO.UTF-8 UTF-8" >> /etc/locale.gen
echo "en_US ISO-8859-1" >> /etc/locale.gen
echo "ro_RO ISO-8859-2" >> /etc/locale.gen
locale-gen

pacstrap /mnt base base-devel vim dialog git

genfstab -U /mnt >> /mnt/etc/fstab

cat <<EOF > rg.ai2.sh
#!/bin/bash

dialog --defaultno --title "Arch Linux install\!" --yesno "Just entered arch-chroot"  7 50 || exit

ln -sf /usr/share/zoneinfo/Europe/Bucharest /etc/localtime

hwclock --systohc --utc

echo "LANG=en_US.UTF-8" >> /etc/locale.conf
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "ro_RO.UTF-8 UTF-8" >> /etc/locale.gen
echo "en_US ISO-8859-1" >> /etc/locale.gen
echo "ro_RO ISO-8859-2" >> /etc/locale.gen
locale-gen

echo "KEYMAP=ro" >> /etc/vconsole.conf
echo "raulgavris" >> /etc/hostname
echo "127.0.0.1       localhost" >> /etc/hosts
echo "::1             localhost" >> /etc/hosts
echo "127.0.1.1       raulgavris.localdomain  raulgavris" >> /etc/hosts

pacman -S --noconfirm --needed sudo zsh os-prober
pacman -S --noconfirm --needed ifplugd wpa_supplicant

pacman --noconfirm --needed -S wireless_tools
pacman --noconfirm --needed -S gnome-keyring
#pacman --noconfirm --needed -S networkmanager
#pacman --noconfirm --needed -S network-manager-applet

#systemctl enable NetworkManager.service

#systemctl enable wpa_supplicant.service
#systemctl enable dhcpcd -> ethernet pc
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

dialog --no-cancel --inputbox "Enter password for root." 10 65 2>rootpasswd

cat <<ROOTPASS | passwd
	${rootpasswd}
	${rootpasswd}
ROOTPASS

pacman --noconfirm --needed -S grub && grub-install --target=i386-pc --recheck /dev/sda && grub-mkconfig -o /boot/grub/grub.cfg

useradd -m -G wheel -s /usr/bin/zsh rg
chsh -s /usr/bin/zsh

pacman -Syyu --noconfirm

#################################################################
# ln -sf /etc/profile ~/.profile # for startx to start everytime
# autostart systemd default session on tty1
# if [[ "$(tty)" == '/dev/tty1' ]]; then
#         exec startx
# fi
# .xinitrc
# #! /bin/bash
# exec i3


#################################################################
#################################################################
#################################################################
######################   RG.AI SCRIPT  ##########################
#################################################################
#################################################################
#################################################################

### OPTIONS AND VARIABLES ###

dotfilesrepo="https://github.com/gavrisraul/dotfiles.git"
progsfile="https://raw.githubusercontent.com/gavrisraul/rg.ai/master/progs.csv"
aurhelper="yay"

### FUNCTIONS ###

error() { clear; printf "ERROR:\\n%s\\n" "$1"; exit;}

welcomemsg() {
	dialog --title "RG.AI\!" --msgbox "Hello\!\\n\\nThis script will install a functional Arch Linux desktop, configured for my taste.\\n\\nSit back and relax, then enjoy my i3-gaps Arch installation.\\n\\n-Raul Gavris" 15 60
}

getuserandpass() {
	# Prompts user for new username and password.
	name=$(dialog --inputbox "Username:" 10 60 3>&1 1>&2 2>&3 3>&1) || exit
	while ! echo "$name" | grep "^[a-z_][a-z0-9_-]*$" >/dev/null 2>&1; do
		name=$(dialog --no-cancel --inputbox "Username not valid. Give a username beginning with a letter, with only lowercase letters, - or _." 10 60 3>&1 1>&2 2>&3 3>&1)
	done
	pass1=$(dialog --no-cancel --passwordbox "Password:" 10 60 3>&1 1>&2 2>&3 3>&1)
	pass2=$(dialog --no-cancel --passwordbox "Password check:" 10 60 3>&1 1>&2 2>&3 3>&1)
	while ! [ "$pass1" = "$pass2" ]; do
		unset pass2
		pass1=$(dialog --no-cancel --passwordbox "Passwords do not match.\\n\\nEnter password again:" 10 60 3>&1 1>&2 2>&3 3>&1)
		pass2=$(dialog --no-cancel --passwordbox "Password check:" 10 60 3>&1 1>&2 2>&3 3>&1)
	done ;
}

usercheck() {
	! (id -u "$name" >/dev/null) 2>&1 ||
	dialog --colors --title "WARNING\!" --yes-label "Install\!" --no-label "Don't install\!" --yesno "The user \"$name\" already exists on this system. This script will \\Zboverwrite\\Zn any conflicting settings/dotfiles on the user account.\\n\\nThis script will \\Zbnot\\Zn overwrite your user files, documents, videos, etc.\\n\\nAlso the password will be changed." 15 70
}

preinstallmsg() {
	dialog --colors --title "The installation is about to start\!" --yes-label "Fuck yeah\!" --no-label "No, nevermind\!" --yesno "The rest of the installation will now be totally automated, so you can sit back and relax.\\n\\nIt will take some time, but when done, you can relax even more with your complete system.\\n\\n\\n\\n\\n\\ZbNow, are you sure you want to continue?\\Zn" 15 60 || { clear; exit; }
}

adduserandpass() {
	# Adds user `$name` with password $pass1.
	dialog --infobox "User \"$name\" added." 4 50
	useradd -m -g wheel -s /bin/bash "$name" >/dev/null 2>&1 ||
	usermod -a -G wheel,audio,video,optical,storage "$name" && mkdir -p /home/"$name" && chown "$name":wheel /home/"$name"
	#groups rg
	echo "$name:$pass1" | chpasswd
	unset pass1 pass2 ;
}

refreshkeys() {
	dialog --infobox "Refreshing Arch Keyring..." 4 40
	pacman --noconfirm -Sy archlinux-keyring >/dev/null 2>&1
}

newperms() { # Set special sudoers settings for install (or after).
	sed -i "/#rg/d" /etc/sudoers
	echo "$* #rg" >> /etc/sudoers ;
}

manualinstall() { # Installs $1 manually if not installed. Used only for AUR helper here.
	[ -f "/usr/bin/$1" ] || (
	dialog --infobox "Installing \"$1\", an AUR helper..." 4 50
	cd /tmp || exit
	rm -rf /tmp/"$1"*
	curl -sO https://aur.archlinux.org/cgit/aur.git/snapshot/"$1".tar.gz &&
	sudo -u "$name" tar -xvf "$1".tar.gz >/dev/null 2>&1 &&
	cd "$1" &&
	sudo -u "$name" makepkg --noconfirm -si >/dev/null 2>&1
	cd /tmp || return) ;
}

maininstall() { # Installs all needed programs from main repo.
	dialog --title "RG.AI Installation" --infobox "Installing \`$1\` ($n of $total). $1 $2" 5 70
	pacman --noconfirm --needed -S "$1" >/dev/null 2>&1
}

gitmakeinstall() {
	dir=$(mktemp -d)
	dialog --title "RG.AI Installation" --infobox "Installing \`$(basename "$1")\` ($n of $total) via \`git\` and \`make\`. $(basename "$1") $2" 5 70
	git clone --depth 1 "$1" "$dir" >/dev/null 2>&1
	cd "$dir" || exit
	make >/dev/null 2>&1
	make install >/dev/null 2>&1
	cd /tmp || return ;
}

aurinstall() {
	dialog --title "RG.AI Installation" --infobox "Installing \`$1\` ($n of $total) from the AUR. $1 $2" 5 70
	echo "$aurinstalled" | grep "^$1$" >/dev/null 2>&1 && return
	sudo -u "$name" $aurhelper -S --noconfirm "$1" >/dev/null 2>&1
}

pipinstall() {
	dialog --title "RG.AI Installation" --infobox "Installing the Python package \`$1\` ($n of $total). $1 $2" 5 70
	command -v pip || pacman -S --noconfirm --needed python-pip python2-pip python3-pip python python2 python3 >/dev/null 2>&1
	yes | pip install "$1"
    yes | pip2 install "$1"
    yes | pip3 install "$1"
}

npminstall() {
    dialog --title "RG.AI Installation" --infobox "Installing the Npm package \`$1\` ($n of $total). $1 $2" 5 70
    command -v npm || pacman -S --noconfirm --needed npm nodejs >/dev/null 2>&1
    yes | npm install -g "$1"
    yes | yarn add "$1"
    # you can use yay -S --noconfirm --needed npm nodejs >/dev/null 2>&1
    # yarn will work because it is installed with pacman and in progs.csv programs are ordered
}

installationloop() {
	([ -f "$progsfile" ] && cp "$progsfile" /tmp/progs.csv) || curl -Ls "$progsfile" | sed '/^#/d' > /tmp/progs.csv
	total=$(wc -l < /tmp/progs.csv)
	aurinstalled=$(pacman -Qm | awk '{print $1}')
	while IFS=, read -r tag program comment; do
		n=$((n+1))
		echo "$comment" | grep "^\".*\"$" >/dev/null 2>&1 && comment="$(echo "$comment" | sed "s/\(^\"\|\"$\)//g")"
		case "$tag" in
			"pacman") maininstall "$program" "$comment" ;;
			"aur") aurinstall "$program" "$comment" ;;
			"git") gitmakeinstall "$program" "$comment" ;;
			"pip") pipinstall "$program" "$comment" ;;
            "npm") npminstall "$program" "$comment" ;;
		esac
	done < /tmp/progs.csv ;
}

putgitrepo() { # Downlods a gitrepo $1 and places the files in $2 only overwriting conflicts
	dialog --infobox "Downloading and installing config files..." 4 60
	dir=$(mktemp -d)
	[ ! -d "$2" ] && mkdir -p "$2" && chown -R "$name:wheel" "$2"
	chown -R "$name:wheel" "$dir"
	sudo -u "$name" git clone --depth 1 "$1" "$dir/gitrepo" >/dev/null 2>&1 &&
	sudo -u "$name" cp -rfT "$dir/gitrepo" "$2"
}

serviceinit() {
    for service in "$@"; do
        dialog --infobox "Enabling \"$service\"..." 4 40
        systemctl enable "$service"
        systemctl start "$service"
	done ;
}

systembeepoff() {
	dialog --infobox "Getting rid of that retarded error beep sound..." 10 50
	rmmod pcspkr
	echo "blacklist pcspkr" > /etc/modprobe.d/nobeep.conf ;
}

resetpulse() {
	dialog --infobox "Reseting Pulseaudio..." 4 50
	killall pulseaudio
	sudo -n "$name" pulseaudio --start ;
}

finalize(){
	dialog --infobox "Preparing welcome message..." 4 50
	dialog --title "The installation process was succesfull\!" --msgbox "Congrats\! Provided there were no hidden errors, the script completed successfully and all the programs and configuration files should be in place.\\n\\nLog out Log in then startx.\\n\\n-Raul Gavris" 10 60
}

### THE ACTUAL SCRIPT ###

### This is how everything happens in an intuitive format and order.

# Check if user is root on Arch distro. Install dialog.
pacman -Syu --noconfirm --needed dialog ||  error "Are you sure you're running this as the root user? Are you sure you're using an Arch-based distro? Are you sure you have an internet connection? Are you sure your Arch keyring is updated?"

# Welcome user.
welcomemsg || error "User exited."

# Get and verify username and password.
getuserandpass || error "User exited."

# Give warning if user already exists.
usercheck || error "User exited."

# Last chance for user to back out before install.
preinstallmsg || error "User exited."

### The rest of the script requires no user input.

adduserandpass || error "Error adding username and/or password."

# Refresh Arch keyrings.
refreshkeys || error "Error automatically refreshing Arch keyring. Consider doing so manually."

dialog --title "RG.AI Installation" --infobox "Installing \`base\`, \`basedevel\` and then \`git\` for installing other software." 5 80
pacman --noconfirm --needed -S base base-devel git >/dev/null 2>&1
[ -f /etc/sudoers.pacnew ] && cp /etc/sudoers.pacnew /etc/sudoers # Just in case

# Allow user to run sudo without password. Since AUR programs must be installed
# in a fakeroot environment, this is required for all builds with AUR.
newperms "%wheel ALL=(ALL) NOPASSWD: ALL"

# Make pacman and yay colorful and adds eye candy on the progress bar because why not.
grep "^Color" /etc/pacman.conf >/dev/null || sed -i "s/^#Color/Color/" /etc/pacman.conf
grep "ILoveCandy" /etc/pacman.conf >/dev/null || sed -i "/#VerbosePkgLists/a ILoveCandy" /etc/pacman.conf
grep "TotalDownload" /etc/pacman.conf || sed -i "/#VerbosePkgLists/a TotalDownload" /etc/pacman.conf

# Use all cores for compilation.
sed -i "s/-j2/-j$(nproc)/;s/^#MAKEFLAGS/MAKEFLAGS/" /etc/makepkg.conf

manualinstall $aurhelper || error "Failed to install AUR helper."

# The command that does all the installing. Reads the progs.csv file and
# installs each needed program the way required. Be sure to run this only after
# the user has been created and has priviledges to run sudo without a password
# and all build dependencies are installed.
installationloop

# Install the dotfiles in the user's home directory
putgitrepo "$dotfilesrepo" "/home/$name"
rm -f "/home/$name/README.md" "/home/$name/LICENSE"

# Pulseaudio, if/when initially installed, often needs a restart to work immediately.
[ -f /usr/bin/pulseaudio ] && resetpulse

# Install vim `plugged` plugins.
sudo -u "$name" mkdir -p "/home/$name/.config/nvim/autoload"
curl "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim" > "/home/$name/.config/nvim/autoload/plug.vim"
dialog --infobox "Installing (neo)vim plugins..." 4 50
(sleep 30 && killall nvim) &
sudo -u "$name" nvim -E -c "PlugUpdate|visual|q|q" >/dev/null 2>&1

serviceinit netctl-auto@wlp3s0 netctl-ifplugd@enp4s0f1

# Most important command! Get rid of the beep!
systembeepoff

# powerline fonts
sudo chown -R {user} /home/{user}/.npm;
cd /tmp;
git clone https://github.com/powerline/fonts.git --depth=1;
cd fonts;
./install.sh;
cd ..;
rm -rf fonts;
cd;

# gestures
sudo gpasswd -a {user} input;
libinput-gestures-setup autostart; libinput-gestures-setup start

# This line, overwriting the `newperms` command above will allow the user to run
# serveral important commands, `shutdown`, `reboot`, updating, etc. without a password.
newperms "%wheel ALL=(ALL) ALL #rg
%wheel ALL=(ALL) NOPASSWD: /usr/bin/shutdown,/usr/bin/reboot,/usr/bin/systemctl suspend,/usr/bin/wifi-menu,/usr/bin/mount,/usr/bin/umount,/usr/bin/pacman -Syu,/usr/bin/pacman -Syyu,/usr/bin/systemctl restart NetworkManager,/usr/bin/rc-service NetworkManager restart,/usr/bin/pacman -Syyu --noconfirm,/usr/bin/loadkeys,/usr/bin/yay,/usr/bin/pacman -Syyuw --noconfirm"

# Last message! Install complete!
finalize
clear
EOF

cp rg.ai2.sh /mnt

arch-chroot /mnt bash rg.ai2.sh

rm rg.ai2.sh /mnt/rg.ai2.sh