#!/usr/bin/env bash
set -euo pipefail

# Install picom
sudo apt install -y picom

# Disable xfwm4 built-in compositor
xfconf-query -c xfwm4 -p /general/use_compositing -s false

# Create picom config
mkdir -p ~/.config/picom
cat > ~/.config/picom/picom.conf <<'EOF'
backend = "glx";
vsync = true;
glx-no-stencil = true;
use-damage = true;

shadow = false;
fading = false;

# Fixes for NVIDIA
glx-no-rebind-pixmap = true;
EOF

# Autostart picom with desktop session
mkdir -p ~/.config/autostart
cat > ~/.config/autostart/picom.desktop <<'EOF'
[Desktop Entry]
Type=Application
Name=Picom Compositor
Exec=picom --config ~/.config/picom/picom.conf
Hidden=false
X-GNOME-Autostart-enabled=true
EOF

# Start picom now
killall picom 2>/dev/null || true
picom --config ~/.config/picom/picom.conf --daemon

echo "Done. Picom is running and will autostart on login."
echo "If anything looks wrong: killall picom"
