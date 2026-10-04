#!/bin/bash

# Script to install Steam on Ubuntu from the multiverse archive (steam-installer).
# Safe to re-run: every step checks whether it is already done first.
#
# The package only installs the bootstrap; Steam downloads and updates the real
# client into ~/.steam on first launch, so the archive version going stale does
# not matter.
#
# Steam is a 32-bit program, so this enables the i386 architecture and, on
# machines using the NVIDIA proprietary driver, installs the matching 32-bit
# GL/Vulkan libraries. Without those Steam falls back to software rendering or
# fails to start.

set -e

if [ "$EUID" -eq 0 ]; then
    echo "Do not run this script as root; it calls sudo itself where needed."
    exit 1
fi

APT_DIRTY=0

# --- i386 architecture -----------------------------------------------------
if dpkg --print-foreign-architectures | grep -qx i386; then
    echo "i386 architecture already enabled, skipping..."
else
    echo "Enabling i386 architecture..."
    sudo dpkg --add-architecture i386
    APT_DIRTY=1
fi

# --- multiverse component --------------------------------------------------
if apt-cache policy | grep -q '/multiverse '; then
    echo "multiverse already enabled, skipping..."
else
    if ! command -v add-apt-repository &> /dev/null; then
        echo "Installing software-properties-common..."
        sudo apt-get update
        sudo apt-get install -y software-properties-common
    fi
    echo "Enabling multiverse..."
    sudo add-apt-repository -y -n multiverse
    APT_DIRTY=1
fi

if [ "$APT_DIRTY" -eq 1 ]; then
    echo "Updating package database..."
    sudo apt-get update
fi

# --- Steam -----------------------------------------------------------------
# noninteractive: the preinst shows a debconf note asking for Debian's
# nvidia-driver-libs:i386, which does not exist on Ubuntu. The Ubuntu
# equivalent is handled below.
if dpkg -s steam-installer &> /dev/null; then
    echo "Steam already installed, skipping..."
else
    echo "Installing Steam..."
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y steam-installer
fi

# --- 32-bit NVIDIA libraries -----------------------------------------------
# Match the branch of the installed amd64 driver (e.g. libnvidia-gl-580); a
# mismatched i386 branch would conflict with the driver.
NVIDIA_GL="$(dpkg-query -W -f '${Package} ${Status}\n' 'libnvidia-gl-*' 2>/dev/null | \
    awk '$NF == "installed" { print $1; exit }')"
if [ -n "$NVIDIA_GL" ]; then
    if dpkg -s "${NVIDIA_GL}:i386" &> /dev/null; then
        echo "${NVIDIA_GL}:i386 already installed, skipping..."
    else
        echo "Installing ${NVIDIA_GL}:i386 for 32-bit OpenGL/Vulkan..."
        sudo apt-get install -y "${NVIDIA_GL}:i386"
    fi
else
    echo "No NVIDIA proprietary driver detected, skipping 32-bit NVIDIA libraries."
fi

echo "Steam installation completed! Run 'steam' to finish the first-time setup."
