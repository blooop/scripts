#!/usr/bin/env bash
# Minimal install: wget, nvm (Node LTS), Claude CLI, Gemini CLI.

sudo apt install -y curl

curl -fsSL https://claude.ai/install.sh | bash

echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc

source ~/.bashrc
