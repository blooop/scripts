#!/bin/bash
# Install Claude Desktop for Linux from Anthropic's APT repo.
# Run as yourself: ~/projects/scripts/install_claude_desktop.sh (it asks for sudo).
set -euo pipefail

key=/usr/share/keyrings/claude-desktop-archive-keyring.asc
url=https://downloads.claude.ai/claude-desktop
list=/etc/apt/sources.list.d/claude-desktop.list

echo "== Get the signing key"
sudo curl -fsSLo "$key" "$url/key.asc"
gpg --show-keys --with-fingerprint "$key" 2>/dev/null || true

echo "== Add the repo"
echo "deb [signed-by=$key] $url/apt/stable stable main" | sudo tee "$list" >/dev/null

echo "== Install"
sudo apt-get update
sudo apt-get install -y claude-desktop

dpkg-query -W -f='Installed ${Package} ${Version}\n' claude-desktop
echo "Start it from the Xubuntu menu, or over SSH: DISPLAY=:0 claude-desktop &"
