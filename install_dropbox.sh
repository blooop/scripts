#!/bin/bash
# install_dropbox.sh
# Script to install Dropbox on Ubuntu/Debian systems


set -e

# Ensure python3-gpg is installed
echo "Installing python3-gpg..."
sudo apt-get update
sudo apt-get install -y python3-gpg

DEB_URL="https://linux.dropbox.com/packages/ubuntu/dropbox_2025.05.20_amd64.deb"
DEB_FILE="dropbox_2025.05.20_amd64.deb"

# Download the Dropbox .deb package
if [ ! -f "$DEB_FILE" ]; then
    echo "Downloading Dropbox .deb package..."
    wget "$DEB_URL" -O "$DEB_FILE"
else
    echo "$DEB_FILE already exists. Skipping download."
fi

# Install the .deb package
sudo dpkg -i "$DEB_FILE" || sudo apt-get install -f -y

echo "Dropbox installation complete."

# Remove the downloaded .deb file
rm -f "$DEB_FILE"
