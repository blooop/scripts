#!/bin/bash

# Script to install Google Cloud CLI on Debian-based Linux distributions

echo "Installing prerequisites..."
if command -v pixi &> /dev/null; then
    echo "Using pixi to install prerequisites..."
    pixi global install curl gnupg ca-certificates
else
    echo "Using apt to install prerequisites..."
    sudo apt-get update
    sudo apt-get install -y apt-transport-https ca-certificates gnupg curl
fi

if [ ! -f /usr/share/keyrings/cloud.google.gpg ]; then
    echo "Adding Google Cloud public signing key..."
    curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
else
    echo "Google Cloud signing key already exists, skipping..."
fi

if [ ! -f /etc/apt/sources.list.d/google-cloud-sdk.list ]; then
    echo "Adding Google Cloud CLI repository..."
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list
else
    echo "Google Cloud repository already exists, skipping..."
fi

echo "Updating package database and installing Google Cloud CLI..."
sudo apt-get update && sudo apt-get install -y google-cloud-cli

echo "Google Cloud CLI installation completed!"
echo "Run 'gcloud init' to initialize the CLI."
