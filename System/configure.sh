# Installing yay
cd ~
git clone https://aur.archlinux.org/yay-bin.git
cd yay-bin
makepkg -sri


# Run after install
PACKAGES="mbpfan-git plymouth-git firefox-decentraleyes firefox-extension-cookie-autodelete firefox-extension-privacybadger firefox-ublock-origin"

yay -S --noconfirm ${PACKAGES}


# Activates
sudo systemctl enable --now  mbpfan-git





#
# GNOME SETTINGS
#

# Setting keybindings
gsettings set org.gnome.mutter experimental-features "['scale-monitor-framebuffer']"
gsettings set org.gnome.desktop.interface gtk-theme "Adwaita-dark"
gsettings set org.gnome.mutter center-new-windows "true"
gsettings set org.gnome.mutter dynamic-workspaces "false"
gsettings set org.gnome.desktop.wm.preferences num-workspaces 4

# Remove these keybindings. cus' they sux
gsettings set org.gnome.shell.keybindings switch-to-application-1 [] 
gsettings set org.gnome.shell.keybindings switch-to-application-2 []  
gsettings set org.gnome.shell.keybindings switch-to-application-3 []  
gsettings set org.gnome.shell.keybindings switch-to-application-4 []  
gsettings set org.gnome.shell.keybindings switch-to-application-5 []  
gsettings set org.gnome.shell.keybindings switch-to-application-6 []  
gsettings set org.gnome.shell.keybindings switch-to-application-7 []  
gsettings set org.gnome.shell.keybindings switch-to-application-8 []  
gsettings set org.gnome.shell.keybindings switch-to-application-9 []  

# Add these cus they are great
gsettings set org.gnome.desktop.wm.keybindings cycle-group "['<Super>0']"
gsettings set org.gnome.desktop.wm.keybindings cycle-group-backward "['<Shift><Super>0']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-1 "['<Shift><Super>exclam']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-2 "['<Shift><Super>quotedbl']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-3 "['<Shift><Super>numbersign']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-4 "['<Shift><Super>currency']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-1 "['<Super>1']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-2 "['<Super>2']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-3 "['<Super>3']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-4 "['<Super>4']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-left "['<Super>h']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-right "['<Super>l']"


#
# Dotfiles
#

cd ~
git clone https://github.com/johan-noren/.dotfiles
cd .dotfiles

echo "git config --global user.email ???"
read git_email

echo "git config --global user.name ???"
read git_name


git config credentials.helper store
git config --global user.email "$git_email"
git config --global user.name "$git_name"


#
# Enable services
#

