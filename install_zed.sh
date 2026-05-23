#!/bin/bash
set -e

if command -v zed &>/dev/null; then
    echo "Zed is already installed: $(zed --version)"
    exit 0
fi

if ! command -v curl &>/dev/null; then
    echo "curl is required but not installed. Installing..."
    sudo apt update && sudo apt install -y curl
fi

echo "Installing Zed editor..."
curl -f https://zed.dev/install.sh | sh

echo "Zed installation completed!"
