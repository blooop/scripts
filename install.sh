#!/bin/bash


# Call sub-install scripts
set -e

./install_apt.sh
./install_pixi.sh
./install_uv.sh
./install_rust.sh
./install_chrome.sh
./install_lazydocker.sh
./install_slack.sh
./install_spotify.sh
