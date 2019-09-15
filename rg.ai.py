#!/bin/usr/python
"""
Script made by Raul Gavriș <rg.raulgavris@gmail.com>, <raulgavris.com>
rg.ai -> raul gavris arch installation
"""
import re
import csv
import subprocess
from dialog import Dialog


d = Dialog(dialog="dialog")
d.set_background_title("rg.ai install Arch Linux!")


user = ''
aurhelper = ''
progs_file = 'https://raw.githubusercontent.com/gavrisraul/rg.ai/master/progs.csv'
dotfiles_gitrepo = 'https://github.com/gavrisraul/dotfiles'


def welcome_message():
    d.msgbox(
        'This script will install Arch Linux with all the configs you choose.',
        height=10, width=30, title='rg.ai script'
    )


def get_user_and_password():
    global user
    user = d.inputbox('Username:', height=10, width=60)[1]
    if not subprocess.call(f'id -u {user}'):
        yesno = d.yesno(
            f'''The user {user} already exists. This will overwrite \
            everything. Do you want to continue?''',
            height=10, width=60
        )
        if yesno == 'cancel':
            return
    while not re.search(r'(^[a-z_][a-z0-9_-]*$)', user):
        user = d.inputbox(
            'Username not valid, must begin with lowercase:',
            height=10, width=60
        )

    pass1 = d.passwordbox('Password:', height=10, width=60)
    pass2 = d.passwordbox('Password check:', height=10, width=60)
    while pass1 != pass2:
        d.msgbox(
            'Sorry the passwords are not the same, try again.',
            height=5, width=35
        )
        pass1 = d.passwordbox('Password:', height=10, width=60)
        pass2 = d.passwordbox('Password check:', height=10, width=60)

    password = pass1

    if not user:
        return

    return (user, password)


def set_user_and_password():
    try:
        user, password = get_user_and_password()
    except:
        d.msgbox(
            'Something is wrong with user or password!', height=5, width=35
        )

    d.infobox(f'User {user} added.', height=5, width=35)
    subprocess.call(
        f'''useradd -m -g wheel -s /bin/bash {user} ||
        usermod -a -G wheel {user} && mkdir -p /home/{user} && \
        chown {user}:wheel /home/{user}''',
        shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
    )

    d.infobox('Password added.', height=5, width=35)
    subprocess.call(
        f'echo "{user}:{password}" | chpasswd',
        shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
    )


def refresh_keys():
    d.infobox('Refreshing Arch Keyring...', height=5, width=35)
    subprocess.call(
        'pacman --noconfirm -Sy archlinux-keyring',
        shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
    )


def new_perms():
    '''Allow user to run sudo withoud password. Since AUR programs must be
    installed in a fakeroot environment, this is required for all builds with
    AUR'''
    subprocess.call(
        '''sed -i "/#rg/d" /etc/sudoers; \
        echo "%wheel ALL=(ALL) ALL #rg" >> /etc/sudoers; \
        echo "%wheel ALL=(ALL) NOPASSWD: /usr/bin/shutdown,/usr/bin/reboot,/usr/bin/systemctl suspend,/usr/bin/wifi-menu,/usr/bin/mount,/usr/bin/umount,/usr/bin/pacman -Syu,/usr/bin/pacman -Syyu,/usr/bin/systemctl restart NetworkManager,/usr/bin/rc-service NetworkManager restart,/usr/bin/pacman -Syyu --noconfirm,/usr/bin/loadkeys,/usr/bin/yay,/usr/bin/pacman -Syyuw --noconfirm"''',
        shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
    )


def install_aurhelper():
    global aurhelper
    aurhelper = d.inputbox('Aurhelper:', height=10, width=60)[1]

    d.infobox(f'Installing aurhelper {aurhelper}.', height=5, width=35)
    subprocess.call(
        '''cd /tmp && curl -sO \
        https://aur.archlinux.org/cgit/aur.git/snapshot/{aurhelper}.tar.gz \
        && sudo -u "{user}" tar -xvf {aurhelper}.tar.gz && cd {aurhelper} \
        && sudo -u "{user}" makepkg --noconfirm -si && cd /tmp''',
        shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
    )


def put_git_repo():
    d.infobox(
        f'Installing dotfiles from {dotfiles_gitrepo}', height=10, width=60
    )
    subprocess.call(
        f'''
        cd /tmp
        git clone https://github.com/gavrisraul/dotfiles.git dotfiles; \
        cd dotfiles; \
        cp -r * /home/{user}; \
        rm -f "/home/{user}/README.md" "/home/{user}/LICENSE" "/home/{user}/.git"
        ''',
        shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
    )


def install_vim_plugins():
    d.infobox('Installing (neo)vim plugins...', height=10, width=50)
    subprocess.call(
        f'''sleep 30 && killall nvim && killall vim \
        sudo -u {user} nvim -E -c "PlugUpgrade|PlugUpdate|visual|q|q"
        ''',
        shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
    )


def system_beep_off():
    d.infobox(
        'Getting rid of that retarded error beep sound...', height=10, width=50
    )
    subprocess.call(
        'rmmod pcspkr; echo "blacklist pcspkr" > /etc/modprobe.d/nobeep.conf;',
        shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
    )


def reset_pulse():
    d.infobox('Resetting pulseaudio...', height=10, width=50)
    subprocess.call(
        f'killall pulseaudio; sudo -n {user} pulseaudio --start;',
        shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
    )


def finalize():
    d.msgbox(
        'Everything is set and ready to be used! Reboot and then startx - rg',
        height=10, width=60, title='Succes!'
    )


def print_message_and_install(tag, program, purpose, current_count, total_count):
    if tag not in('pacman', 'aur'):
        return

    d.infobox(
        f'''Installing from {tag}, the program {program} to be \
        used for {purpose} ... program {current_count} / {total_count}''',
        height=10, width=60
    )

    if tag == 'pacman':
        subprocess.call(
            f'pacman --noconfirm --needed -S {program}',
            shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
        )
    elif tag == 'aur':
        subprocess.call(
            f'sudo -u "{user}" {aurhelper} -S --noconfirm {program}',
            shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
        )
    elif tag == 'git':
        subprocess.call(
            f'''cd /tmp; git clone --depth 1 {program} {program}; \
            cd {program}; make; make install; cd /tmp''',
            shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
        )
    elif tag == 'pip':
        subprocess.call(
            f'''pip install {program}; pip2 install {program}; \
            pip3 install {program}''',
            shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
        )
    elif tag == 'npm':
        subprocess.call(
            f'npm install -g {program}; yarn add {program}',
            shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
        )


def main_loop():
    with open('progs.csv') as csv_file:
        csv_reader = csv.reader(csv_file, delimiter=',')
        row_count = sum(1 for row in csv_reader)
        for index, row in enumerate(csv_reader):
            print_message_and_install(
                tag=row[0],
                program=row[1],
                purpose=row[2],
                current_count=index - 1,
                total_count=row_count
            )


subprocess.call(
    'pacman -Syyu --noconfirm --needed dialog',
    shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
)

welcome_message()

get_user_and_password()

set_user_and_password()

refresh_keys()

d.infobox('Installing base, basedevel and git...', height=10, width=35)
subprocess.call(
    'pacman --noconfirm --needed -S  base base-devel git',
    shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
)

new_perms()

# make pacman and aur installer colorful and use all cores for compilation
subprocess.call(
    '''
    grep "^Color" /etc/pacman.conf || sed -i "s/^#Color/Color/" /etc/pacman.conf; \
    grep "ILoveCandy" /etc/pacman.conf || sed -i "/#VerbosePkgLists/a ILoveCandy" /etc/pacman.conf; \
    grep "TotalDownload" /etc/pacman.conf || sed -i "/#VerbosePkgLists/a TotalDownload" /etc/pacman.conf \
    sed -i "s/-j2/-j$(nproc)/;s/^#MAKEFLAGS/MAKEFLAGS/" /etc/makepkg.conf; \
    ''',
    shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
)

install_aurhelper()

main_loop()

put_git_repo()

install_vim_plugins()

reset_pulse()

system_beep_off()

d.infobox('Installing powerline fonts...', height=10, width=35)
subprocess.call(
    f'''sudo chown -R {user} /home/{user}/.npm; \
    git clone https://github.com/powerline/fonts.git --depth=1; \
    cd fonts; \
    ./install.sh; \
    cd ..; \
    rm -rf fonts;''',
    shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
)

finalize()
