#!/bin/bash

#TODO:
# [x] .zshrc isn't copied
# [x] .hushlogin must be added
# [x] bluetooth service failing
# [ ] yay not compiling (also not mbpfan-git)
# [x] wireless issues. -> iwd.conf and systemd-resolved 

# before
# loadkeys sv-latin1
# iwctl station wlan0 scan
# iwctl station wlan0 get-networks
# iwctl station wlan0 connect <SSID>

## VARIABLES ##
ENCRYPTION_PASSPHRASE="temp"
ROOT_PASSWORD="lemp"

USERNAME="testu"
USER_PASSWORD="pemp"

# Misc settings
HOSTNAME="hosty"
CONTINENT_CITY="Europe/Stockholm"

# Install system to
TARGET_DISK="/dev/sda"

# Size of swapfile
SWAP_SIZE="12"

# Setting mountflags
MOUNT_OPTIONS="defaults,x-mount.mkdir"
MOUNT_OPTIONS_BTRFS="${MOUNT_OPTIONS},compress=lzo,ssd,noatime"

# Kernel options
CPU_MICROCODE="intel-ucode"
KERNEL_OPTIONS="i915.fastboot=1 i915.enable_fbc=1 i915.enable_guc=2 rw quiet loglevel=3 vt.global_cursor_default=0 rd.luks.options=discard rd.systemd.show_status=0 rd.udev.log-priority=3 nmi_watchdog=0"

# The mkinitcpio.conf file will be modified with the modules and hooks below
INITRAMFS_MODULES="intel_agp i915 btrfs"
INITRAMFS_BINARIES="btrfs"
INITRAMFS_HOOKS="base systemd block autodetect modconf keyboard sd-vconsole sd-encrypt filesystems"

# Graphic stuff
GPU_DRIVERS="vulkan-intel intel-media-driver "
LIBVA_ENVIRONMENT_VARIABLE="export LIBVA_DRIVER_NAME=iHD"


# Sets packages to be installed
SWAYWM="sway swaybg swayidle swaylock mako bemenu-wlroots alacritty udisks2 udiskie light mpv imv grim slurp wl-clipboard wf-recorder"
PACKAGES="base base-devel linux linux-headers linux-firmware efibootmgr btrfs-progs e2fsprogs device-mapper $CPU_MICROCODE $GPU_DRIVERS $SWAYWM ffmpeg bluez pipewire libpipewire02 libva-utils iwd zsh ufw cryptsetup openssh upower thermald unzip unrar powertop ttf-dejavu xdg-user-dirs wget git man-db man-pages neovim firefox diffutils"
AUR_PACKAGES="mbpfan-git "






echo "Updating system clock"
timedatectl set-ntp true

echo "Syncing packages database"
pacman -Sy --noconfirm


## SETTING UP DISKS ##
echo "Creating partitions"
sgdisk --clear \
       --new=1:0:+550MiB --typecode=1:ef00    --change-name=1:EFI \
       --new=2:0:0       --typecode=2:8300    --change-name=2:encryptedSystemPartition \
       $TARGET_DISK
           
echo "Setting up cryptographic volume"
mkdir -p -m0700 /run/cryptsetup
echo "$ENCRYPTION_PASSPHRASE" | cryptsetup -q -h sha512 -s 512 --use-random --type luks2 luksFormat /dev/disk/by-partlabel/encryptedSystemPartition
echo "$ENCRYPTION_PASSPHRASE" | cryptsetup luksOpen /dev/disk/by-partlabel/encryptedSystemPartition systemPartition

echo "Setting up EFI"
mkfs.fat -F32 -n LINUXEFI /dev/disk/by-partlabel/EFI


echo "Setting up BTRFS"
# Temporarily mount system
mkfs.btrfs -L systemPartition /dev/mapper/systemPartition
mount -t btrfs LABEL=systemPartition /mnt

# Create subvolumns
btrfs subvol create /mnt/root
btrfs subvol create /mnt/home
btrfs subvol create /mnt/swap
btrfs subvol create /mnt/snapshots

# Unmount
umount -R /mnt

# Mount subvolumes
mount -t btrfs -o subvol=root,$MOUNT_OPTIONS_BTRFS LABEL=systemPartition /mnt
mount -t btrfs -o subvol=home,$MOUNT_OPTIONS_BTRFS LABEL=systemPartition /mnt/home
mount -t btrfs -o subvol=snapshots,$MOUNT_OPTIONS_BTRFS LABEL=systemPartition /mnt/.snapshots

# Mount EFI
mkdir /mnt/boot
mount /dev/disk/by-partlabel/EFI /mnt/boot

## INSTALLING PACKAGES ##
echo "Installing Arch Linux"
yes '' | pacstrap /mnt $PACKAGES 


## GENERATING FSTAB AND CRYPTTAB ##
echo "Generating fstab"
genfstab -L -p /mnt >> /mnt/etc/fstab

# Add swap-partition
echo "LABEL=systemPartition /swap  btrfs  rw,noatime,ssd,space_cache,subvol=/swap,subvol=swap     0 0" >> /mnt/etc/fstab


## CHROOTING TOOTHING PART ##
echo "Configuring new system"
arch-chroot /mnt /bin/bash << EOF

echo "Setting system clock"
timedatectl set-timezone $CONTINENT_CITY
ln -sf /usr/share/zoneinfo/${CONTINENT_CITY} /etc/localtime
timedatectl set-ntp true
#hwclock --systohc --localtime REMOVE


echo "Setting locales"
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "sv_SE.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen

tee -a /etc/locale.conf << END
LANG=sv_SE.UTF-8
LC_CTYPE="sv_SE.UTF-8"
LC_NUMERIC="sv_SE.UTF-8"
LC_TIME="sv_SE.UTF-8"
LC_COLLATE="sv_SE.UTF-8"
LC_MONETARY="sv_SE.UTF-8"
LC_MESSAGES="en_US.UTF-8"
LC_PAPER="sv_SE.UTF-8"
LC_NAME="sv_SE.UTF-8"
LC_ADDRESS="sv_SE.UTF-8"
LC_TELEPHONE="sv_SE.UTF-8"
LC_MEASUREMENT="sv_SE.UTF-8"
LC_IDENTIFICATION="sv_SE.UTF-8"
LC_ALL=
END

echo "Configuring console"
tee -a /etc/vconsole.conf << END
KEYMAP=sv-latin1
#FONT=ter-v32n
COLOR_0=2e3440
COLOR_1=bf616a
COLOR_2=a3be8c
COLOR_3=ebcb8b
COLOR_4=81a1c1
COLOR_5=b48ead
COLOR_6=88c0d0
COLOR_7=e5e9f0
COLOR_8=4c566a
COLOR_9=bf616a
COLOR_10=a3be8c
COLOR_11=ebcb8b
COLOR_12=81a1c1
COLOR_13=b48ead
COLOR_14=8fbcbb
COLOR_15=eceff4
END

echo "Setting hostname"
echo $HOSTNAME > /etc/hostname


echo "Setting root password"
echo -en "$ROOT_PASSWORD\n$ROOT_PASSWORD" | passwd


echo "Generating initramfs"
sed -i 's/^HOOKS.*/HOOKS=($INITRAMFS_HOOKS)/' /etc/mkinitcpio.conf
sed -i 's/^MODULES.*/MODULES=($INITRAMFS_MODULES)/' /etc/mkinitcpio.conf
sed -i 's/^BINARIES.*/BINARIES=($INITRAMFS_BINARIES)/' /etc/mkinitcpio.conf
sed -i 's/#COMPRESSION="lz4"/COMPRESSION="lz4"/g' /etc/mkinitcpio.conf
mkinitcpio -P


echo "Setting up systemd-boot"
bootctl --path=/boot install
mkdir -p /boot/loader/
tee -a /boot/loader/loader.conf << END
default arch.conf
timeout 0
END

mkdir -p /boot/loader/entries/
touch /boot/loader/entries/arch.conf
tee -a /boot/loader/entries/arch.conf << END
title Arch Linux
linux /vmlinuz-linux
initrd /$CPU_MICROCODE.img
initrd /initramfs-linux.img
options luks.name=$(blkid -s UUID -o value /dev/sda2)=systemPartition root=UUID=$(blkid -s UUID -o value /dev/mapper/systemPartition) rootflags=subvol=root $KERNEL_OPTIONS
END

# TODO: HIBERNATION SUPPORT WOULD BE NICE IN THE FUTURE. 


echo "Setting up Pacman hook for automatic systemd-boot updates"
mkdir -p /etc/pacman.d/hooks/
touch /etc/pacman.d/hooks/systemd-boot.hook
tee -a /etc/pacman.d/hooks/systemd-boot.hook << END
[Trigger]
Type = Package
Operation = Upgrade
Target = systemd
[Action]
Description = Updating systemd-boot
When = PostTransaction
Exec = /usr/bin/bootctl update
END


echo "Setting up swap"
echo "Mounting swapfile subvolume"
mkdir /swap
mount -o noatime,subvol=swap /dev/mapper/systemPartition /swap

echo "Creating swapfile"
truncate -s 0 /swap/swapfile
chattr +C /swap/swapfile
btrfs property set /swap/swapfile compression none
fallocate -l "$SWAP_SIZE"G /swap/swapfile

echo "Setting correct permissions and formatting to swap"
mkswap /swap/swapfile
chmod 600 /swap/swapfile

echo "Activating swapfile"
swapon /swap/swapfile

echo "Adding swap entry to fstab"
tee -a /etc/fstab << END
#/dev/mapper/systemPartition /swap btrfs rw,noatime,space_cachesubvol=@swap 0 0
/swap/swapfile none swap defaults,discard 0 0
END


echo "Setting swappiness to 20"
touch /etc/sysctl.d/99-swappiness.conf
echo 'vm.swappiness=20' > /etc/sysctl.d/99-swappiness.conf


echo "Enabling periodic TRIM"
systemctl enable fstrim.timer


echo "Installing UDEV rules"

tee -a /etc/udev/rules.d/40-disable_wakeup_from_xhc1.rules << END
SUBSYSTEM=="pci", KERNEL=="0000:00:14.0", ATTR{power/wakeup}="disabled"
END

tee -a /etc/udev/rules.d/50-allow_user_to_change_backlight.rules << END
ACTION=="add", SUBSYSTEM=="backlight", RUN+="/bin/chgrp wheel /sys/class/backlight/%k/brightness"
ACTION=="add", SUBSYSTEM=="backlight", RUN+="/bin/chmod g+w /sys/class/backlight/%k/brightness"
END

#touch /mnt/etc/udev/rules.d/51-allow_user_to_change_kbd_led.rules 
tee -a /etc/udev/rules.d/51-allow_user_to_change_kbd_led.rules << END
ACTION=="add", KERNEL=="smc::kbd_backlight", SUBSYSTEM=="leds", RUN+="/bin/chgrp wheel /sys/class/leds/smc::kbd_backlight/brightness"
ACTION=="add", KERNEL=="smc::kbd_backlight", SUBSYSTEM=="leds", RUN+="/bin/chmod g+w /sys/class/leds/smc::kbd_backlight/brightness"
END


echo "Setting kernel to hush"
echo "kernel.printk = 3 3 3 3" > /etc/sysctl.d/10-hush-kernel.conf


echo "Installing systemd services"
touch /etc/systemd/system/disable_gpe4E.service
tee -a /etc/systemd/system/disable_gpe4E.service << END
[Unit]
Description=the service that disables GPE 4E, an interrupt that is going crazy on Macs

[Service]
ExecStart=/usr/bin/bash -c 'echo "disable" > /sys/firmware/acpi/interrupts/gpe4E'

[Install]
WantedBy=multi-user.target
END

systemctl enable disable_gpe4E

echo "Adding user as a sudoer"
echo '%wheel ALL=(ALL) ALL' | EDITOR='tee -a' visudo

# Make sure that screen is not cleared before login
mkdir -p /etc/systemd/system/getty@tty1.service.d/
touch /etc/systemd/system/getty@tty1.service.d/50-prevent_clearscreen_before_console.conf
tee -a /etc/systemd/system/getty@tty1.service.d/50-prevent_clearscreen_before_console.conf << END
[Service]
TTYVTDisallocate=no
END

# Cursor on
setterm -cursor on >> /etc/issue

# Enable
systemctl enable iwd

#echo "Installing yay"
#cd /tmp
#git clone https://aur.archlinux.org/yay-bin.git
#cd yay-bin
#makepkg -si --noconfirm

#echo "Installing some additionall packages from AUR"
#yay -S --noconfirm $



echo "Enabling audio power saving features"
touch /etc/modprobe.d/audio_powersave.conf
tee -a /etc/modprobe.d/audio_powersave.conf << END
options snd_hda_intel power_save=1
END


echo "Enabling wifi (iwlwifi) power saving features"
touch /etc/modprobe.d/iwlwifi.conf
tee -a /etc/modprobe.d/iwlwifi.conf << END
options iwlwifi power_save=1 
END


echo "Reducing VM writeback time"
touch /etc/sysctl.d/dirty.conf
tee -a /etc/sysctl.d/dirty.conf << END
vm.dirty_writeback_centisecs = 1500
END


echo "Setting environment variables (and improve Java applications font rendering)"
tee -a /etc/environment << END
$LIBVA_ENVIRONMENT_VARIABLE
export _JAVA_OPTIONS='-Dawt.useSystemAAFontSettings=gasp'
export JAVA_FONTS=/usr/share/fonts/TTF
END


echo "Installing and configuring UFW"
systemctl enable ufw
systemctl start ufw
ufw enable
ufw default deny incoming
ufw default allow outgoing


echo "Enabling thermald"
systemctl enable thermald.service


echo "Enabling bluetooth"
systemctl enable bluetooth.service

echo "Configuring network"
mkdir -p /etc/iwd
touch /etc/iwd/main.conf
tee -a /etc/iwd/main.conf << END
[General]
EnableNetworkConfiguration=true

[Network]
NameResolvingService=systemd
END

echo "Enabling systemd-resolved"
systemctl enable systemd-resolved.service

#echo "Enabling mbpfan"
#systemctl enable mbpfan.service


# Meningless stuff. 
touch /etc/skel/.hushlogin

echo "Setting terminal defaults"
touch /etc/skel/.zshrc
tee -a /etc/skel/.zshrc << END
HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000

bindkey -e
zstyle ':completion:*' use-ip true
setopt NO_CASE_GLOB
autoload -Uz compinit
compinit

# ALIASES
alias vi='nvim '
alias sudo='sudo '
alias ls='ls --color=auto'

# PROMPT
export PS1='
%B%F{white}%d%f%b '

export GDK_BACKEND=wayland
export MOZ_ENABLE_WAYLAND=1
export MOZ_USE_XINPUT2=1
export QT_QPA_PLATFORM=wayland-egl
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export EDITOR=/bin/nvim
export BROWSER=/bin/firefox
export PATH=$PATH:~/.local/bin
END



echo "Creating new user"
useradd -m -G wheel,video -s /bin/bash $USERNAME
echo -en "$USER_PASSWORD\n$USER_PASSWORD" | passwd $USERNAME
chsh -s /bin/zsh $USERNAME


## INLINE BOOTSTRAP SCRIPT ENDS HERE ##
EOF
echo "Cleaning up"
umount -R /mnt
swapoff -a


echo "Sequence finished."
