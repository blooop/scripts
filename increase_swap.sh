#!/bin/bash
# Disable the swap file
echo "Disabling the swap file..."
sudo swapoff /swapfile

# Create a 4GB swap file
echo "Allocating 16GB for the swap file..."
sudo fallocate -l 16G /swapfile

# Mark the file as a swap file
echo "Marking the file as a swap file..."
sudo mkswap /swapfile

# Enable the swap file
echo "Enabling the swap file..."
sudo swapon /swapfile

# Display the current swap file usage and size
echo "Current swap file status:"
swapon --show