#!/bin/bash

cd ~/home/cptvmt

# installation paquet


# base
pacman -S xorg-server xorg-xinit xterm neofetch git
# fonts
pacman -S ttf-linux-libertine ttf-inconsolata
# dependence suckless tools
pacman -S libx11 libxft libxinerama freetype2 fontconfig


# configuration


localectl set-x11-keymap fr


# installer suckless truc (temps pas besoin plus tard)
mkdir .suckless
cd .suckless

git clone https://git.suckless.org/dwm
git clone https://git.suckless.org/st
git clone https://git.suckless.org/dmenu

cd dwm
make
sudo make clean install
cd..
cd st
make
sudo make clean install
cd ..
cd dmenu
make
sudo make clean install
cd

touch .xinitrc