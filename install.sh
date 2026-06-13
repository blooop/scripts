#!/bin/bash

# Call sub-install scripts
set -e

./install_apt.sh
# ./install_pixi.sh  # handled by chezmoi dotfiles bootstrap
./install_uv.sh
# ./install_rust.sh  # handled by pixi global sync
./install_chrome.sh
# ./install_lazydocker.sh  # handled by pixi global sync
./install_slack.sh
./install_spotify.sh
./set_default_terminal.sh
./install_claude.sh
