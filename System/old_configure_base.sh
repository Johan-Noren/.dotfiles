#!/bin/bash

# Detect username
USERNAME=$(whoami)

# Install different packages according to GPU vendor (Intel, AMDGPU) 
CPU_VENDOR=$(cat /proc/cpuinfo | grep vendor | uniq)
GPU_DRIVERS="vulkan-intel lib32-vulkan-intel intel-media-driver libvdpau-va-gl"
LIBVA_ENVIRONMENT_VARIABLE="export LIBVA_DRIVER_NAME=iHD"
VDPAU_ENVIRONMENT_VARIABLE="export VDPAU_DRIVER=va_gl"


echo "Syncing repos and updating packages"
sudo pacman -Syu --noconfirm


echo "Installing and configuring UFW"
sudo pacman -S --noconfirm ufw
sudo systemctl enable ufw
sudo systemctl start ufw
sudo ufw enable
sudo ufw default deny incoming
sudo ufw default allow outgoing


echo "Installing GPU drivers"
sudo pacman -S --noconfirm mesa $gpu_drivers vulkan-icd-loader


echo "Improving hardware video accelaration"
sudo pacman -S --noconfirm ffmpeg libva-utils libva-vdpau-driver vdpauinfo


echo "Installing common applications"
sudo pacman -S --noconfirm  openssh links htop powertop p7zip git ripgrep unzip fwupd unrar


echo "Configuring shell"
chsh -s /usr/bin/zsh


echo "Creating user's folders"
sudo pacman -S --noconfirm xdg-user-dirs


echo "Installing fonts"
sudo pacman -S --noconfirm ttf-roboto ttf-roboto-mono ttf-droid ttf-opensans ttf-dejavu ttf-liberation ttf-hack noto-fonts ttf-fira-code ttf-fira-mono ttf-font-awesome noto-fonts-emoji ttf-hanazono adobe-source-code-pro-fonts ttf-cascadia-code inter-font


echo "Set environment variables and alias"
touch ~/.zshrc
tee -a ~/.zshrc << EOF
HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000
bindkey -e
zstyle ':completion:*' use-ip true
setopt NO_CASE_GLOB
autoload -Uz compinit
compinit

# CALCULATOR
autoload -U zcalc
function __calc_plugin { zcalc -e "$*" }
aliases[calc]='noglob __calc_plugin'
aliases[=]='noglob __calc_plugin'

# ALIASES
alias vi='nvim '
alias sudo='sudo '
alias ls='ls --color=auto'

# PROMPT
export PS1='
%B%F{white}%d%f%b '

unset GLOBAL_RCS

export GDK_BACKEND=wayland
export MOZ_ENABLE_WAYLAND=1
export MOZ_USE_XINPUT2=1
export QT_QPA_PLATFORM=wayland-egl
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export EDITOR=/bin/nvim
export BROWSER=/bin/firefox
export GTK_THEME='Adwaita:dark'

export PATH=$PATH:~/.local/bin
EOF


echo "Installing yay"
git clone https://aur.archlinux.org/yay-bin.git
cd yay-bin
makepkg -si --noconfirm
cd ..
rm -rf yay-bin


echo "Installing and configuring Plymouth"
yay -S --noconfirm plymouth-git
sudo sed -i 's/base systemd block/base systemd sd-plymouth block/g' /etc/mkinitcpio.conf
sudo sed -i 's/rd.udev.log-priority=3 nmi_watchdog=0/rd.udev.log-priority=3 splash nmi_watchdog=0/g' /boot/loader/entries/arch.conf
sudo mkinitcpio -p linux
sudo plymouth-set-default-theme -R bgrt


if [[ $cpu_vendor =~ "GenuineIntel" ]]
    then
        echo "Installing and starting thermald"
        sudo pacman -S --noconfirm thermald
        sudo systemctl start thermald.service
        sudo systemctl enable thermald.service
    fi


if [[ $(cat /sys/class/dmi/id/chassis_type) -eq 10 ]]
then
echo "Improving laptop battery"
echo "Enabling audio power saving features"
sudo touch /etc/modprobe.d/audio_powersave.conf
sudo tee -a /etc/modprobe.d/audio_powersave.conf << EOF
options snd_hda_intel power_save=1
EOF


echo "Enabling wifi (iwlwifi) power saving features"
sudo touch /etc/modprobe.d/iwlwifi.conf
sudo tee -a /etc/modprobe.d/iwlwifi.conf << EOF
options iwlwifi power_save=1
EOF


echo "Reducing VM writeback time"
sudo touch /etc/sysctl.d/dirty.conf
sudo tee -a /etc/sysctl.d/dirty.conf << EOF
vm.dirty_writeback_centisecs = 1500
EOF
fi


echo "Setting environment variables (and improve Java applications font rendering)"
sudo tee -a /etc/environment << EOF
$libva_environment_variable
$vdpau_environment_variable
export _JAVA_OPTIONS='-Dawt.useSystemAAFontSettings=gasp'
export JAVA_FONTS=/usr/share/fonts/TTF
EOF


echo "Enabling bluetooth"
sudo systemctl start bluetooth.service
sudo systemctl enable bluetooth.service


echo "Disabling root (still allows sudo)"
passwd --lock root


echo "Installing pipewire multimedia framework"
sudo pacman -S --noconfirm pipewire libpipewire02
