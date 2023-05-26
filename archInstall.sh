#!/bin/bash


###################################
# SCRIPT D'INSTALATION ARCH LINUX #
###################################


# COMMENT UTILISER CE SCRIPT
#
# booter la clé :
#
# brancher une clé avec arch linux dedans
# vous pouvez le faire en telechargeant l'iso d'arch sur leur site oficiel
# et umount /dev/sdX?* (remplacer X par la lettre attribué a la clé usb (faire lsblk -S))
# puis faire 
# sudo dd if=/chemin/vers/image.iso of=/dev/sdX bs=4M status=progress conv=fdatasync
# attendre un peu sa va etre long puis pour ejecter la clé :
# umount /media/nom-clé
# sudo eject /dev/sdX
# udisksctl power-off -b /dev/sdX
#
# lancer iso :
#
# brancher la clé sur votre pc et redemarrer le
# pendant le lancement spammer la touche pour acceder au BIOS (F2/F12/F11/...)
# une fois dans le bios lancer avec la clé
# puis séléctionné install arch (ou un truc dans le genre)
#
# installer script :
#
# faite loadkeys fr-latin1 (ou autre)
# pour faciliter l'ecriture des commandes qui suivent
# car par defaut le clavier est en qwerty
#
# l'installation ce fait par git, donc il faut installer git:
# pacman -Sy git
#
# git clone https://github.com/CaptainBoulbi/linuxrc.git
# cd linuxrc
# 
# le script est le archInstall.sh
# 
# configurer script :
#
# modifier la valeur des variable ci dessous pour personaliser votre installation
# chaque variable a son explication a coté
#
# une fois la configuration faite, faite :
# chmod +x ./archInstall.sh
# ./archInstall.sh
#
# attendez que l'instalation ce fini puis eteindre le pc (demander a la fin de l'install)
# enlevez la clé et re allumer votre pc
#
# et voila.


# VARIABLE DE CONFIGURATION DE L'INSTALATION

# user
HOSTNAME=pc					# nom de la machine
ROOTPWD=pass				# mdp en root
USRNAME=usr					# nom de l'utilisateur principale
USRPWD=$ROOTPWD				# mdp utilisateur principale
SUDOERS=1					# 1=droit sudo; 0=pas droit sudo
SUDOSANSPASSWD=1			# sudo cmd sans mdp (1=true;0=false)
LOGATBOOT=1					# au lancement se connecter automatiquement utile pour crypter

# langue
LANGUE_CLAVIER=fr-latin1 	# liste langue clavier : ls /usr/share/kbd/keymaps/**/*.map.gz
LANG=en_US					# langue géneral : cat /etc/locale.gen
POLICE=default8x16 			# liste police dispo : ls /usr/share/kbd/consolefonts/
TIMEZONE=Europe/Paris 		# liste timezone : timedatectl list-timezones

# disque
DISKNAME=sda				# nom du disque par defaut sda sinon lsblk
ENCRYPTED=0					# crypte le disque (0=false;1=true)
PASSPHRASE=$ROOTPWD			# mdp pour decrypté la partition crypté
SIZEBOOTPART=1				# taille boot partition conseiller 1G min
SIZEHOMEPART=				# `` home ``, si !defini : reste taille disque <!> G at end
OVERWRITEDISK=0				# ecrit random data sur part home (tres long) (0=false;1=true)

# install
STEPBYSTEP=0				# doit confirmer pour passer a etape suivante (debug mode)
INSTALLGUI=1				# install config perso

# FONCTION / VARIABLE DU PROG

NEXT=0
next(){
	NEXT=$(expr $NEXT + 1)
	echo step $NEXT : $*
	if [ $STEPBYSTEP -eq 1 ]; then
		read
	fi
}

if [ $SUDOSANSPASSWD -eq 1 ]; then
	SUDOSANSPASSWD="NOPASSWD: ALL"
else
	SUDOSANSPASSWD=ALL
fi

# SCRIPT

next "change la langue du claver"
loadkeys $LANGUE_CLAVIER

next "change police"
setfont $POLICE

next "met a jour lheure et date a la timezone"
timedatectl set-timezone $TIMEZONE
# synchronise hardware (mdr jsp ce que sa fait mais c'est bien de le faire askip)
hwclock --systohc

next "partitione disque differament si crypter activé ou pas"
if [ $ENCRYPTED -eq 1 ]; then

	next "??? création table de partition ???"
	echo "w" | fdisk /dev/$DISKNAME

	next "partionne le disque en deux (boot et home)"
	echo ","$SIZEBOOTPART"G" | sfdisk /dev/$DISKNAME 1	# part pour boot (sda1)
	echo ","$SIZEHOMEPART | sfdisk /dev/$DISKNAME 2		# part pour home (sda2)
	
	next "formatte la partition pour le boot dans le format fat"
	mkfs.fat -F32 /dev/$DISKNAME"1"

	if [ $OVERWRITEDISK -eq 1 ]; then
		next "remplit le disque de donné random pour rendre ilisible les meta-donné"
		dd if=/dev/urandom of=/dev/$DISKNAME"2"
	fi

	next "active lencryption (jsp si cest un vrai mot) la partition sda2"
	echo $PASSPHRASE | cryptsetup luksFormat /dev/$DISKNAME"2"
	# open crypt part
	echo $PASSPHRASE | cryptsetup open /dev/$DISKNAME"2" lolol
	
	next "crée un file system"
	mkfs.btrfs /dev/mapper/lolol

	next "monte la partition crypté"
	mount /dev/mapper/lolol /mnt

	next "crée le dossier boot dans la part crypté et le monte sur la partition boot"
	mkdir /mnt/boot
	mount /dev/$DISKNAME"1" /mnt/boot

	next "cree var pour config decrypt"
	UUIDPART=$(lsblk -f | grep $DISKNAME"2" | awk '{print $4}')
	UUIDCRYPT=$(lsblk -f | grep lolol | awk '{print $3}')
	GRUBCONF="GRUB_CMDLINE_LINUX_DEFAULT=\\\"loglevel=3 quiet cryptdevice=UUID=$UUIDPART:cryptlvm root=UUID=$UUIDCRYPT\\\""

else
	next "??? création table de partition ???"
	echo "w" | fdisk /dev/$DISKNAME
    
	next "partionne le disque en deux (boot et home)"
	echo ","$SIZEBOOTPART"G" | sfdisk /dev/$DISKNAME 1	# part pour boot (sda1)
	echo ","$SIZEHOMEPART | sfdisk /dev/$DISKNAME 2		# part pour home (sda2)
    
	if [ $OVERWRITEDISK -eq 1 ]; then
		next "remplit le disque de donné random pour rendre ilisible les meta-donné"
		dd if=/dev/urandom of=/dev/$DISKNAME"1"
	fi
    
	next "formate file format disk"
	mkfs.ext4 /dev/$DISKNAME"1"
	mkfs.ext4 /dev/$DISKNAME"2"
    
	next "monte les partition"
	mount /dev/$DISKNAME"2" /mnt
	mkdir /mnt/boot
	mount /dev/$DISKNAME"1" /mnt/boot
fi

next "met a jour la mirrorlist pour mettre les liens les plus rapides en haut"
mv /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.old
reflector --country France --age 12 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
cat /etc/pacman.d/mirrorlist.old >> /etc/pacman.d/mirrorlist
rm /etc/pacman.d/mirrorlist.old 

next "installer paquet de base dans partition"
if [ $ENCRYPTED -eq 1 ]; then
	pacstrap -K /mnt base base-devel linux linux-firmware man-db man-pages grub cryptsetup lvm2 networkmanager vim neovim efibootmgr
else
	pacstrap -K /mnt base base-devel linux linux-firmware man-db man-pages grub networkmanager vim neovim efibootmgr
fi

next "crée le script a lancé dans chroot"
cat <<EOF> /mnt/script.sh
#!/bin/bash

NEXTI=0
next(){
	echo step chroot : \$*
	if [ $STEPBYSTEP -eq 1 ]; then
		read
	fi
}

next "etape du script chrooter"
next "maj timezone"
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
# met a jour l'hardware sur la date
hwclock --systohc

next "configure la langue"
sed -i "s/#$LANG/$LANG/g" /etc/locale.gen
locale-gen
echo "LANG=$LANG.UTF-8" > /etc/locale.conf

next "configure la langue du clavier"
loadkeys $LANGUE_CLAVIER
echo "KEYMAP=$LANGUE_CLAVIER" > /etc/vconsole.conf

next "definie le nom de la machine"
echo $HOSTNAME > /etc/hostname

next "fait des truc bizare avec lip et le nom de la machine, mais cest important"
echo -e "\n127.0.0.1\tlocalhost\n::1\t\tlocalhost\n127.0.1.1\t$HOSTNAME.localdomain $HOSTNAME" >> /etc/hosts

next "active le prog qui gere les connections internet"
systemctl enable NetworkManager

next "cree le mdp root"
echo "root:$ROOTPWD" | chpasswd

next "creer le compte user"
useradd -m $USRNAME
echo "$USRNAME:$USRPWD" | chpasswd
if [ $SUDOERS -eq 1 ]; then
	sed -i "s/^# %wheel.*) $SUDOSANSPASSWD$/%wheel ALL=(ALL:ALL) $SUDOSANSPASSWD/g" /etc/sudoers
	usermod -aG wheel $USRNAME
fi

if [ $LOGATBOOT -eq 1 ]; then
	sudo mkdir -p /etc/systemd/system/getty@tty1.service.d/
	echo "# /etc/systemd/system/getty@tty1.service.d/override.conf" >> /etc/systemd/system/getty@tty1.service.d/override.conf
	echo "[Service]" >> /etc/systemd/system/getty@tty1.service.d/override.conf
	echo "ExecStart=" >> /etc/systemd/system/getty@tty1.service.d/override.conf
	echo "ExecStart=-/usr/bin/agetty --autologin $USRNAME --noclear %I \$TERM" >> /etc/systemd/system/getty@tty1.service.d/override.conf
fi

if [ $ENCRYPTED -eq 1 ]; then
	next "active config pour decrypt au lancement"
	sed -i "s/^HOOKS.*$/HOOKS=(base udev autodetect modconf kms keyboard keymap consolefont block encrypt lvm2 filesystems fsck)/g" /etc/mkinitcpio.conf
	mkinitcpio -p linux

	next "config grub pour crypt"
	sed -i "s/^GRUB_CMDLINE_LINUX_DEFAULT.*$/$GRUBCONF/g" /etc/default/grub
fi

next "genere grug config"
grub-install /dev/$DISKNAME
# si ligne du dessus fonctionne pas : grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=grub
grub-mkconfig -o /boot/grub/grub.cfg
genfstab -U /mnt >> /mnt/etc/fstab
EOF

next "lance chroot avec la suite du script"
arch-chroot /mnt chmod +x /script.sh
arch-chroot /mnt /script.sh
arch-chroot /mnt rm /script.sh

if [ $INSTALLGUI -eq 1 ]; then
	arch-chroot /mnt sudo ./linuxrc.sh
fi

next "reboot"
echo apuyer sur entrez pour redemarrer le pc, noubliez pas de retirez la clé
read
reboot
