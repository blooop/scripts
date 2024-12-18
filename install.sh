#!/bin/bash

sudo apt update

wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo dpkg -i google-chrome-stable_current_amd64.deb


#lazydocker
curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash

sudo apt install -y python3-pip tmux byobu neovim git git-lfs filelight ripgrep pinta nvtop htop 
pip install rockervsc nvtop
snap install slack spotify
sudo snap install code --classic

#for ifconfig
sudo apt install net-tools

sudo apt install fd-find
ln -s $(which fdfind) ~/.local/bin/fd

git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install --all

sudo apt install -y dolphin konsole kio-gdrive


sudo add-apt-repository ppa:christian-boxdoerfer/fsearch-stable -y
sudo apt update
sudo apt install fsearch

#pulseaudio from https://gist.github.com/the-spyke/2de98b22ff4f978ebf0650c90e82027e

sudo apt install -y pipewire-media-session- wireplumber pipewire-audio-client-libraries
systemctl --user --now enable wireplumber.service 
sudo cp /usr/share/doc/pipewire/examples/alsa.conf.d/99-pipewire-default.conf /etc/alsa/conf.d/
sudo apt install -y libldacbt-{abr,enc}2 libspa-0.2-bluetooth pulseaudio-module-bluetooth-
#reboot now, afterwards check with cmd:
LANG=C pactl info | grep '^Server Name'