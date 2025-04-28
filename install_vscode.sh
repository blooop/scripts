#!/bin/bash

# Script to download and install the latest Visual Studio Code

echo "Downloading the latest VS Code .deb package..."
wget -O vscode.deb "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64"

echo "Installing Visual Studio Code..."
sudo dpkg -i vscode.deb

echo "Cleaning up downloaded files..."
rm vscode.deb

echo "Installing Dev Containers extension..."
code --install-extension ms-vscode-remote.remote-containers

# Add the devcontainer CLI to PATH
DEVCONTAINER_CLI_PATH="$HOME/.config/Code/User/globalStorage/ms-vscode-remote.remote-containers/cli-bin"

# Wait a moment for the extension to finish installation and create the CLI directory
echo "Setting up Dev Containers CLI..."
sleep 3

# Check if the directory exists, create if it doesn't
if [ ! -d "$DEVCONTAINER_CLI_PATH" ]; then
    echo "Creating Dev Containers CLI directory..."
    mkdir -p "$DEVCONTAINER_CLI_PATH"
fi

# Add to PATH in .bashrc if not already there
if ! grep -q "$DEVCONTAINER_CLI_PATH" "$HOME/.bashrc"; then
    echo "Adding Dev Containers CLI to PATH..."
    echo 'export PATH="$DEVCONTAINER_CLI_PATH:$PATH"' >> ~/.bashrc
    echo "Dev Containers CLI path added to .bashrc"
fi

echo "Visual Studio Code installation completed!"
echo "Dev Containers extension installed and CLI added to PATH."
echo "Please restart your terminal or run 'source ~/.bashrc' to use the devcontainer CLI."