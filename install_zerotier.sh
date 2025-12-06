#!/bin/bash
# install_zerotier.sh
# Installs ZeroTier using the official installation script

set -e

curl -s https://install.zerotier.com | sudo bash

echo "\nZeroTier installation complete."
echo "To connect to a ZeroTier network, run:"
echo "sudo zerotier-cli join NETWORK_ID"
