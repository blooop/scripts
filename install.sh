#!/bin/bash

sudo apt update

#basic dev tools
sudo apt install -y curl python3-pip tmux byobu neovim git git-lfs fd-find ripgrep pinta nvtop htop net-tools 

# Install package managers
# Install pixi
curl -fsSL https://pixi.sh/install.sh | bash

# Install uv
curl -LsSf https://astral.sh/uv/install.sh | sh

# Install Rust and Cargo
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source "$HOME/.cargo/env"

wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo dpkg -i google-chrome-stable_current_amd64.deb

#lazydocker
curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash

#set up rocker development environment tool
uv tool install rocker 
uv tool install rockerc 
uv tool install rockervsc 

snap install slack spotify
sudo snap install code --classic

#disk space usage
sudo apt install filelight

#command line fuzzy search
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install --all

#better file manager with tabs and inbuilt console
sudo apt install -y dolphin konsole 

#global search as you type gui
sudo add-apt-repository ppa:christian-boxdoerfer/fsearch-stable -y
sudo apt update
sudo apt install fsearch
