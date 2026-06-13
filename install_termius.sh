#!/bin/bash
# install_termius.sh
# Installs Termius from the official .deb.
# Prefers the .deb over the snap, consistent with the rest of this repo.

set -e

URL="https://www.termius.com/download/linux/Termius.deb"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

echo "Downloading Termius..."
curl -fsSL -o "$tmp/termius.deb" "$URL"
chmod 644 "$tmp/termius.deb"
echo "Installing..."
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "$tmp/termius.deb" > /dev/null

echo "Termius installed."
