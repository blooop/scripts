#!/bin/bash
# install_protonvpn.sh
# Installs the Proton VPN desktop app from Proton's official apt repository.
# The release .deb only holds the apt source and Proton's signing key, so it is
# checked against a pinned SHA-256 before install. After that the app updates
# via 'apt upgrade'.

set -e

VERSION=1.0.8
SHA256=0b14e71586b22e498eb20926c48c7b434b751149b1f2af9902ef1cfe6b03e180
DEB="protonvpn-stable-release_${VERSION}_all.deb"
URL="https://repo.protonvpn.com/debian/dists/stable/main/binary-all/${DEB}"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

echo "Downloading Proton VPN repository package ${VERSION}..."
curl -fsSL -o "$tmp/$DEB" "$URL"
echo "$SHA256  $tmp/$DEB" | sha256sum -c --quiet - || {
    echo "Checksum mismatch. Check https://protonvpn.com/support/official-linux-vpn-ubuntu and update VERSION/SHA256." >&2
    exit 1
}
chmod 644 "$tmp/$DEB"
sudo dpkg -i "$tmp/$DEB"

echo "Installing Proton VPN and tray icon support..."
sudo apt-get update -qq
pkgs="proton-vpn-gnome-desktop libayatana-appindicator3-1 gir1.2-ayatanaappindicator3-0.1"
# GNOME Shell needs an extension to show tray icons; Xfce and KDE do not.
if command -v gnome-shell > /dev/null; then
    pkgs="$pkgs gnome-shell-extension-appindicator"
fi
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq $pkgs > /dev/null

echo "Proton VPN installed. Start \"Proton VPN\" from the app menu and log in."
