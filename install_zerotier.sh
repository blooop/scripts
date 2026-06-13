#!/bin/bash
# install_zerotier.sh
# Installs ZeroTier and configures DNS via zerotier-systemd-manager

set -e

# Install ZeroTier
curl -s https://install.zerotier.com | sudo bash

# Accept DNS from the ZeroTier network
sudo zerotier-cli set 9f77fc393e07ad6a allowDNS=1

# Install the bridge between ZeroTier DNS and systemd-resolved
wget https://github.com/zerotier/zerotier-systemd-manager/releases/download/v0.4.0/zerotier-systemd-manager_0.4.0_linux_amd64.deb
sudo dpkg -i zerotier-systemd-manager_0.4.0_linux_amd64.deb
rm zerotier-systemd-manager_0.4.0_linux_amd64.deb
sudo systemctl daemon-reload
sudo systemctl enable --now zerotier-systemd-manager.timer

# Enable systemd-networkd to read the DNS config
sudo systemctl enable --now systemd-networkd
sudo systemctl disable systemd-networkd-wait-online.service

echo "ZeroTier installation and DNS configuration complete!"
