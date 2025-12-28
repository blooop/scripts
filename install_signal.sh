#!/bin/bash

# Script to install Signal Desktop on Debian-based Linux distributions
# NOTE: This only works for 64-bit Debian-based systems (Ubuntu, Mint, etc.)

echo "Installing Signal Desktop official public signing key..."
wget -O- https://updates.signal.org/desktop/apt/keys.asc | gpg --dearmor > signal-desktop-keyring.gpg
cat signal-desktop-keyring.gpg | sudo tee /usr/share/keyrings/signal-desktop-keyring.gpg > /dev/null

echo "Adding Signal Desktop repository..."
wget -O signal-desktop.sources https://updates.signal.org/static/desktop/apt/signal-desktop.sources
cat signal-desktop.sources | sudo tee /etc/apt/sources.list.d/signal-desktop.sources > /dev/null

echo "Updating package database and installing Signal Desktop..."
sudo apt update && sudo apt install -y signal-desktop

echo "Cleaning up downloaded files..."
rm signal-desktop-keyring.gpg signal-desktop.sources

echo "Signal Desktop installation completed!"
