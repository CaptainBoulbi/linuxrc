#!/bin/bash

cd ~

# installation paquet


# base
sudo pacman -S --noconfirm xorg-server xorg-xinit xterm neofetch git
# fonts
sudo pacman -S --noconfirm ttf-linux-libertine ttf-inconsolata
# dependence suckless tools et xorg
sudo pacman -S --noconfirm libx11 libxft libxinerama freetype2 fontconfig xf86-video-vmware


# configuration


localectl set-x11-keymap fr


# installer suckless truc (temps pas besoin plus tard)
mkdir .suckless
cd .suckless

git clone https://git.suckless.org/dwm
git clone https://git.suckless.org/st
git clone https://git.suckless.org/dmenu

cd dwm
sudo make
sudo make clean install
cd..
cd st
sudo make
sudo make clean install
cd ..
cd dmenu
sudo make
sudo make clean install
cd

touch .xinitrc
echo "exec /usr/local/bin/dwm" > .xinitrc

echo "[[ ! \$DISPLAY && \$XDG_VTNR -eq 1 ]] && startx" >> .bash_profile

echo "installatin fini, appuez sur entrez pour redemarrer"
read
reboot
