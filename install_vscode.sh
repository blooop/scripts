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

