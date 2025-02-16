#!/bin/bash

# Install necessary packages
sudo apt update
sudo apt install -y curl wget git

# Call the new pipewire installation script
./install_pipewire.sh

# Install other dependencies
sudo apt install -y build-essential libssl-dev

echo "Installation complete. Please reboot your system."
