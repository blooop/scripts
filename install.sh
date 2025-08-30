#!/bin/bash

sudo apt update

#basic dev tools
sudo apt install -y curl python3-pip tmux byobu neovim git git-lfs ripgrep pinta nvtop htop net-tools terminator

# Install pixi
curl -fsSL https://pixi.sh/install.sh | bash

#install basic dev tools
pixi global install fzf fd-find ripgrep

# Install uv
curl -LsSf https://astral.sh/uv/install.sh | sh
source $HOME/.local/bin/env

#set up rocker development environment tool
uv tool install rocker 
uv tool install rockerc 
uv tool install rockervsc 

# Install Rust and Cargo
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source "$HOME/.cargo/env"

wget https://dl.google.com/linux/direct/
sudo dpkg -i google-chrome-stable_current_amd64.deb
rm google-chrome-stable_current_amd64.deb

#lazydocker
curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash

snap install slack spotify
sudo snap install code --classic
