#!/bin/bash

# One-liner setup for new machines using chezmoi + pixi
#
# During setup, you'll be prompted:
#   - Install Rust? [y/N]
#
# All other tools are installed automatically.

# === WGET VERSION (recommended - wget usually pre-installed) ===
wget -qO- https://pixi.sh/install.sh | bash &&
  export PATH="$HOME/.pixi/bin:$PATH" &&
  pixi global install chezmoi &&
  chezmoi init --apply https://github.com/blooop/dotfiles &&
  pixi global sync

# === CURL VERSION ===
sudo apt update && sudo apt install -y curl &&
  curl -fsSL https://pixi.sh/install.sh | bash &&
  export PATH="$HOME/.pixi/bin:$PATH" &&
  pixi global install chezmoi &&
  chezmoi init --apply https://github.com/blooop/dotfiles &&
  exec bash #to source new environment
