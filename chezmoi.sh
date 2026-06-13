#!/bin/bash

sudo apt update && sudo apt install -y curl &&
  curl -fsSL https://pixi.sh/install.sh | bash &&
  export PATH="$HOME/.pixi/bin:$PATH" &&
  pixi global install chezmoi &&
  chezmoi init --apply https://github.com/blooop/dotfiles &&
  exec bash #to source new environment
