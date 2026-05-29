#!/usr/bin/env bash
set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    exec sudo "$0" "$@"
fi

SERVICE_NAME="max-performance"

echo "Setting CPU governor to performance..."
for gov in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    echo performance > "$gov"
done

echo "Setting NVIDIA GPU to Prefer Maximum Performance..."
nvidia-settings -a "[gpu:0]/GPUPowerMizerMode=1" >/dev/null 2>&1 || true

# Systemd service for CPU governor (runs before desktop)
echo "Installing systemd service for CPU..."
cat > /etc/systemd/system/${SERVICE_NAME}.service <<'EOF'
[Unit]
Description=Set CPU governor to performance
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'for gov in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do echo performance > "$gov"; done'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable ${SERVICE_NAME}.service

# Autostart entry for GPU (needs display session)
AUTOSTART_DIR="$(eval echo ~${SUDO_USER:-$USER})/.config/autostart"
mkdir -p "$AUTOSTART_DIR"
cat > "$AUTOSTART_DIR/nvidia-max-performance.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=NVIDIA Max Performance
Exec=nvidia-settings -a "[gpu:0]/GPUPowerMizerMode=1"
Hidden=false
X-GNOME-Autostart-enabled=true
EOF

echo "Done. CPU governor persists via systemd, GPU via session autostart."
