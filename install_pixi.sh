#!/bin/bash

set -e

# Install pixi
wget -qO- https://pixi.sh/install.sh | sh

# Add pixi autocompletion to bashrc
echo 'eval "$(pixi completion --shell bash)"' >> ~/.bashrc
# install basic dev tools
source ~/.bashrc


# Ensure pixi is in PATH for this script
export PATH="$HOME/.pixi/bin:$PATH"


