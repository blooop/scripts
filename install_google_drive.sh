#!/bin/bash
set -e

echo "Installing GNOME Online Accounts for Google Drive integration..."

sudo apt update
sudo apt install -y gnome-online-accounts gvfs-backends gnome-control-center

echo ""
echo "Installation complete!"
echo "Opening Online Accounts settings..."
echo ""
echo "Click 'Google' to add your Google account."
echo "Your Google Drive will then appear in your file manager."

gnome-control-center online-accounts
