#!/bin/bash

# Script to install Docker Engine and the NVIDIA Container Toolkit on Ubuntu.
# Safe to re-run: every step checks whether it is already done first.
#
# Docker:  https://docs.docker.com/engine/install/ubuntu/
# NVIDIA:  https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html
#
# Note: the engine is not available via pixi/conda-forge (conda-forge ships only
# docker-cli and docker-compose, no dockerd/containerd and no NVIDIA toolkit),
# so this has to come from apt.

set -e

if [ "$EUID" -eq 0 ]; then
    echo "Do not run this script as root; it calls sudo itself where needed."
    exit 1
fi

APT_DIRTY=0

# Compare a sources.list line against a file, ignoring whitespace differences,
# so re-runs do not rewrite an equivalent entry and force a needless apt update.
same_line() {
    [ -f "$1" ] || return 1
    [ "$(tr -s '[:space:]' ' ' < "$1" | sed 's/^ *//;s/ *$//')" = \
      "$(echo "$2" | tr -s '[:space:]' ' ' | sed 's/^ *//;s/ *$//')" ]
}

MISSING=""
for pkg in ca-certificates curl gnupg; do
    dpkg -s "$pkg" &> /dev/null || MISSING="$MISSING $pkg"
done
if [ -n "$MISSING" ]; then
    echo "Installing prerequisites:$MISSING"
    sudo apt-get update
    # shellcheck disable=SC2086
    sudo apt-get install -y $MISSING
else
    echo "Prerequisites already installed, skipping..."
fi

# --- Remove distro packages that conflict with docker-ce -------------------
CONFLICTING=""
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
    if dpkg -s "$pkg" &> /dev/null; then
        CONFLICTING="$CONFLICTING $pkg"
    fi
done
if [ -n "$CONFLICTING" ]; then
    echo "Removing conflicting packages:$CONFLICTING"
    # shellcheck disable=SC2086
    sudo apt-get remove -y $CONFLICTING
else
    echo "No conflicting docker packages installed, skipping..."
fi

# --- Docker apt repository -------------------------------------------------
if [ ! -f /etc/apt/keyrings/docker.asc ]; then
    echo "Adding Docker public signing key..."
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc
else
    echo "Docker signing key already exists, skipping..."
fi

# shellcheck disable=SC1091
CODENAME="$(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")"
# shellcheck disable=SC1091
OS_VERSION_ID="$(. /etc/os-release && echo "$VERSION_ID")"

# Docker does not always publish a suite on release day; fall back if missing.
if ! curl -fsSL -o /dev/null "https://download.docker.com/linux/ubuntu/dists/${CODENAME}/Release"; then
    echo "Docker has no apt suite for '${CODENAME}' yet, falling back to 'noble'..."
    CODENAME=noble
fi

DOCKER_LIST="deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu ${CODENAME} stable"
if ! same_line /etc/apt/sources.list.d/docker.list "$DOCKER_LIST"; then
    echo "Adding Docker repository (${CODENAME})..."
    echo "$DOCKER_LIST" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    APT_DIRTY=1
else
    echo "Docker repository already configured for '${CODENAME}', skipping..."
fi

# --- NVIDIA Container Toolkit apt repository -------------------------------
# Only worth configuring if there is a working driver to talk to.
HAS_GPU=0
if command -v nvidia-smi &> /dev/null && nvidia-smi -L &> /dev/null; then
    HAS_GPU=1
fi

if [ "$HAS_GPU" -eq 1 ]; then
    NVIDIA_KEYRING=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
    if [ ! -f "$NVIDIA_KEYRING" ]; then
        echo "Adding NVIDIA Container Toolkit public signing key..."
        curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | \
            sudo gpg --dearmor -o "$NVIDIA_KEYRING"
    else
        echo "NVIDIA Container Toolkit signing key already exists, skipping..."
    fi

    NVIDIA_LIST="$(curl -fsSL https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
        sed "s#deb https://#deb [signed-by=${NVIDIA_KEYRING}] https://#g")"
    if ! same_line /etc/apt/sources.list.d/nvidia-container-toolkit.list "$NVIDIA_LIST"; then
        echo "Adding NVIDIA Container Toolkit repository..."
        echo "$NVIDIA_LIST" | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list > /dev/null
        APT_DIRTY=1
    else
        echo "NVIDIA Container Toolkit repository already configured, skipping..."
    fi
else
    echo "No working NVIDIA driver detected (nvidia-smi failed), skipping NVIDIA Container Toolkit."
    echo "Install a driver first (e.g. 'sudo ubuntu-drivers install'), reboot, then re-run this script."
fi

# --- Install ---------------------------------------------------------------
if [ "$APT_DIRTY" -eq 1 ]; then
    echo "Updating package database..."
    sudo apt-get update
fi

echo "Installing Docker Engine..."
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

if [ "$HAS_GPU" -eq 1 ]; then
    # nvidia-docker2 is deprecated and is NOT needed; nvidia-container-toolkit
    # is what `nvidia-ctk runtime configure` wires into the docker daemon.
    echo "Installing NVIDIA Container Toolkit..."
    sudo apt-get install -y nvidia-container-toolkit

    DAEMON_JSON=/etc/docker/daemon.json
    BEFORE="$(sudo md5sum "$DAEMON_JSON" 2>/dev/null | cut -d' ' -f1)"
    sudo nvidia-ctk runtime configure --runtime=docker
    AFTER="$(sudo md5sum "$DAEMON_JSON" 2>/dev/null | cut -d' ' -f1)"
    if [ "$BEFORE" != "$AFTER" ]; then
        echo "Docker runtime configuration changed, restarting docker..."
        sudo systemctl restart docker
    else
        echo "Docker already configured for the nvidia runtime, skipping restart..."
    fi
fi

sudo systemctl enable --now docker

# --- Let the current user use docker without sudo --------------------------
# docker-ce creates the group, so only create it if it is somehow missing.
if ! getent group docker > /dev/null; then
    echo "Creating docker group..."
    sudo groupadd docker
fi

if id -nG "$USER" | grep -qw docker; then
    echo "$USER is already in the docker group, skipping..."
else
    echo "Adding $USER to the docker group..."
    sudo usermod -aG docker "$USER"
    echo "Log out and back in for this to take effect."
fi

# --- Smoke tests -----------------------------------------------------------
# Run via sudo: a freshly added group does not apply to the current shell, and
# Ubuntu 26.04 removed both `sg` and `newgrp`.
echo "Testing docker..."
sudo docker run --rm hello-world > /dev/null && echo "docker OK"

if [ "$HAS_GPU" -eq 1 ]; then
    echo "Testing GPU passthrough..."
    # Use a plain ubuntu image matching the host release rather than an
    # nvidia/cuda one: the toolkit injects nvidia-smi and the driver libraries
    # from the host, so this tests passthrough without pinning a CUDA version.
    # (nvidia/cuda ubuntu26.04 tags only exist for CUDA >= 13.3, which needs a
    # newer driver than the 580 branch provides.)
    TEST_IMAGE="ubuntu:${OS_VERSION_ID}"
    if sudo docker run --rm --gpus all "$TEST_IMAGE" nvidia-smi > /dev/null; then
        echo "nvidia docker OK"
    else
        echo "WARNING: GPU container test failed."
    fi
fi

echo "Docker installation completed!"
