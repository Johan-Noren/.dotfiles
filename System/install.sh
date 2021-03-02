#!/bin/bash

# before
# loadkeys sv-latin1
# iwctl 

ENCRYPTION_PASSPHRASE=""
ROOT_PASSWORD=""
USER_PASSWORD=""
HOSTNAME="hosty"
USERNAME="testu"
CONTINENT_CITY="Europe/Stockholm"

TARGET_DISK="/dev/sda"
PARTITION1="${TARGET_DISK1}"
PARTITION2="${TARGET_DISK2}"
PARTITION3="${TARGET_DISK3}"
PARTITION4="${TARGET_DISK4}"
SWAP_SIZE="8" # same as ram if using hibernation, otherwise minimum of 8

# Set different microcode, kernel params and initramfs modules according to CPU vendor
CPU_VENDOR=$(cat /proc/cpuinfo | grep vendor | uniq)
CPU_MICROCODE="intel-ucode"

# Kernel options to
KERNEL_OPTIONS="i915.fastboot=1 i915.enable_fbc=1 i915.enable_guc=2 rw quiet loglevel=3 vt.global_cursor_default=0  
rd.luks.options=discard rd.systemd.show_status=0 rd.udev.log-priority=3 nmi_watchdog=0"

# The mkinitcpio.conf file will be modified with the modules and hooks below
INITRAMFS_MODULES="intel_agp i915 btrfs"
INITRAMFS_HOOKS="base systemd block autodetect modconf keyboard sd-vconsole sd-encrypt filesystems"

# Sets packages to be installed
PACKAGES="base base-devel linux linux-headers linux-firmware efibootmgr btrfs-progs e2fsprogs device-mapper $CPU_MICROCODE zsh cryptsetup networkmanager wget man-db man-pages neovim diffutils flatpak"


echo "Updating system clock"
timedatectl set-ntp true


echo "Syncing packages database"
pacman -Sy --noconfirm


echo "Creating partitions"
printf "o\nY\nw\nY\n" | gdisk $TARGET_DISK
printf "n\n1\n\n+512M\nef00\nw\ny\n" | gdisk $TARGET_DISK
printf "n\n2\n\n\n8300\nw\ny\n" | gdisk $TARGET_DISK


echo "Setting up cryptographic volume"
mkdir -p -m0700 /run/cryptsetup
echo "$ENCRYPTION_PASSPHRASE" | cryptsetup -q -h sha512 -s 512 --use-random --type luks2 luksFormat $PARTITION2
echo "$ENCRYPTION_PASSPHRASE" | cryptsetup luksOpen $PARTITION2 cryptroot


echo "Formatting the partitions"
mkfs.fat -F32 -n LINUXEFI $PARTITION1
mkfs.btrfs -L Arch /dev/mapper/cryptroot


echo "Setting up BTRFS"
mount -o compress=zstd,noatime /dev/mapper/cryptroot /mnt
btrfs subvol create /mnt/@
btrfs subvol create /mnt/@home
btrfs subvol create /mnt/@swap


mkdir /mnt/snapshots
btrfs subvol create /mnt/snapshots/@
btrfs subvol create /mnt/snapshots/@home


umount /mnt
mount -o compress=zstd,noatime,subvol=@ /dev/mapper/cryptroot /mnt
mkdir -p /mnt/{boot,home,.snapshots/root,.snapshots/home}
mount -o compress=zstd,noatime,subvol=@home /dev/mapper/cryptroot /mnt/home
mount -o compress=zstd,noatime,subvol=/snapshots/@ /dev/mapper/cryptroot /mnt/.snapshots/root
mount -o compress=zstd,noatime,subvol=/snapshots/@home /dev/mapper/cryptroot /mnt/.snapshots/home
mount $PARTITION1 /mnt/boot



echo "Installing Arch Linux"
yes '' | pacstrap /mnt $PACKAGES 


echo "Generating fstab"
genfstab /mnt >> /mnt/etc/fstab


echo "Configuring new system"
arch-chroot /mnt /bin/bash << EOF


echo "Setting system clock"
timedatectl set-ntp true
timedatectl set-timezone $CONTINENT_CITY
hwclock --systohc --localtime


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


echo "Creating new user"
useradd -m -G wheel,video -s /bin/bash $USERNAME
echo -en "$USER_PASSWORD\n$USER_PASSWORD" | passwd $USERNAME


echo "Generating initramfs"
sed -i 's/^HOOKS.*/HOOKS=($INITRAMFS_HOOKS)/' /etc/mkinitcpio.conf
sed -i 's/^MODULES.*/MODULES=($INITRAMFS_MODULES)/' /etc/mkinitcpio.conf
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
initrd /$cpu_microcode.img
initrd /initramfs-linux.img
options rd.luks.name=$(blkid -s UUID -o value /dev/vda2)=cryptroot root=/dev/mapper/cryptroot rootflags=subvol=@ $KERNEL_OPTIONS
END

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
mount -o noatime,subvol=@swap /dev/mapper/cryptroot /swap

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
#/dev/mapper/cryptroot /swap btrfs rw,noatime,space_cachesubvol=@swap 0 0
/swap/swapfile none swap defaults,discard 0 0
END

echo "Setting swappiness to 20"
touch /etc/sysctl.d/99-swappiness.conf
echo 'vm.swappiness=20' > /etc/sysctl.d/99-swappiness.conf


echo "Enabling periodic TRIM"
systemctl enable fstrim.timer


echo "Enabling NetworkManager"
systemctl enable NetworkManager


echo "Adding user as a sudoer"
echo '%wheel ALL=(ALL) ALL' | EDITOR='tee -a' visudo
EOF


echo "Cleaning up"
umount -R /mnt
swapoff -a


echo "Arch Linux is ready. You can reboot now!"
