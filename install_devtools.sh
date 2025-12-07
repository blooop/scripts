#!/bin/bash

set -e

# Ensure pixi is installed and in PATH
if ! command -v pixi &> /dev/null; then
    echo "pixi not found. Please run install_pixi.sh first or install pixi manually."
    exit 1
fi

# Install global dev tools using pixi
pixi global install fzf fd-find ripgrep byobu nvtop htop chezmoi lazygit lazydocker git git-lfs

pixi global install --channel https://prefix.dev/github-releases neovim

#+ Set up fzf key bindings and fuzzy completion
echo 'eval "$(fzf --bash)"' >> ~/.bashrc