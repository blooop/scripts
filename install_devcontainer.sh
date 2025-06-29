#!/bin/bash

# Check if node is installed
if ! command -v node >/dev/null 2>&1; then
  echo "Node.js not found. Installing nvm and Node.js..."
  # Install nvm
  wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  nvm install --lts
else
  echo "Node.js is already installed."
fi

# Ensure npm is available (should be with node)
if ! command -v npm >/dev/null 2>&1; then
  echo "npm not found. Please check your Node.js installation."
  exit 1
fi

# Install devcontainer CLI
echo "Installing @devcontainers/cli globally..."
npm install -g @devcontainers/cli