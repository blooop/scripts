#!/bin/bash
# install_gnome_online_accounts.sh
# Installs GNOME Online Accounts and opens the settings to add a Google account

set -e

echo "Installing GNOME Online Accounts..."
sudo apt-get update
sudo apt-get install -y gnome-online-accounts

echo "Installation complete. Opening Online Accounts settings..."
env XDG_CURRENT_DESKTOP=GNOME gnome-control-center online-accounts &

echo "Add your Google account in the settings window that just opened."
echo "Once signed in, Google Drive will be available in the file manager."
