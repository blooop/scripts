#!/bin/bash

set -e

echo "Installing Proton VPN for Ubuntu/Linux..."

echo "Step 1: Downloading repository package..."
wget -O protonvpn-stable-release_1.0.8_all.deb https://repo.protonvpn.com/debian/dists/stable/main/binary-all/protonvpn-stable-release_1.0.8_all.deb

echo "Step 2: Installing repository configuration..."
sudo dpkg -i ./protonvpn-stable-release_1.0.8_all.deb
sudo apt update

echo "Step 3: Installing Proton VPN application..."
sudo apt install -y proton-vpn-gnome-desktop

echo "Step 4: Installing optional system tray support..."
sudo apt install -y libayatana-appindicator3-1 gir1.2-ayatanaappindicator3-0.1 gnome-shell-extension-appindicator

echo "Cleaning up downloaded package..."
rm -f protonvpn-stable-release_1.0.8_all.deb

echo ""
echo "Installation complete!"
echo "You can now launch Proton VPN from your applications menu."
echo "Note: Restart the Proton VPN app after installation to enable system tray icon."
echo ""
echo "To uninstall later, run:"
echo "sudo apt autoremove proton-vpn-gnome-desktop && sudo apt purge protonvpn-stable-release"