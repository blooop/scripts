#!/bin/bash
# install_neovim.sh: Installs Neovim stable from PPA and Python support packages

set -e

# Ensure software-properties-common is installed
# sudo apt-get update
# sudo apt-get install -y software-properties-common

# Add Neovim stable PPA
sudo add-apt-repository -y ppa:neovim-ppa/stable
sudo apt-get update

# Install Neovim
sudo apt-get install -y neovim

# Install Python development and pip packages for both Python 2 and 3
#sudo apt-get install -y python-dev python-pip python3-dev python3-pip

echo "Neovim and Python support installed successfully."
