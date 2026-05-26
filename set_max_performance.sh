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

echo "Installing systemd service..."
cat > /etc/systemd/system/${SERVICE_NAME}.service <<'EOF'
[Unit]
Description=Set CPU and GPU to maximum performance
After=multi-user.target nvidia-persistenced.service

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'for gov in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do echo performance > "$gov"; done'
ExecStart=/usr/bin/nvidia-settings -a "[gpu:0]/GPUPowerMizerMode=1"
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable ${SERVICE_NAME}.service

echo "Done. Max performance applied now and on every boot."
