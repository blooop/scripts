#!/bin/bash
# install_slack.sh
# Installs Slack from the official .deb.
# Avoids the snap, which prompts "Allow snap 'slack' to change ..." on every
# launch on non-GNOME desktops because snapd userd unconditionally shows the
# URL-scheme-handler confirmation dialog.

set -e

VERSION=4.49.89
URL="https://downloads.slack-edge.com/desktop-releases/linux/x64/${VERSION}/slack-desktop-${VERSION}-amd64.deb"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

echo "Downloading Slack ${VERSION}..."
curl -fsSL -o "$tmp/slack.deb" "$URL"
chmod 644 "$tmp/slack.deb"
echo "Installing..."
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "$tmp/slack.deb" > /dev/null

echo "Slack ${VERSION} installed. Future updates come via 'apt upgrade' (Slack's .deb adds its own apt source)."
