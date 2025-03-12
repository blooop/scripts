#!/bin/bash

# Script to download and install Cursor

echo "Downloading the Cursor .deb package..."
wget -O cursor.deb "https://downloader.cursor.sh/linux/deb/x64"

echo "Installing Cursor..."
sudo dpkg -i cursor.deb

# Install dependencies if needed
if [ $? -ne 0 ]; then
    echo "Fixing dependencies..."
    sudo apt install -f -y
fi

echo "Cleaning up downloaded files..."
rm cursor.deb

echo "Cursor installation completed!"
