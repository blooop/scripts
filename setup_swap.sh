#!/usr/bin/env bash
# setup-swap.sh — Persist NVMe swap tuning and zram tier-0 swap
# Run with: sudo bash setup-swap.sh
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Error: must run as root (sudo $0)"
    exit 1
fi

echo "=== Installing sysctl tuning ==="
tee /etc/sysctl.d/99-nvme-swap.conf <<'EOF'
# Aggressive NVMe swap tuning
vm.swappiness=200
vm.page-cluster=0
vm.vfs_cache_pressure=500
vm.watermark_boost_factor=0
vm.watermark_scale_factor=10
EOF
sysctl --system
echo "  sysctl params installed and loaded."

echo ""
echo "=== Installing zram swap service ==="
tee /etc/systemd/system/zram-swap.service <<'EOF'
[Unit]
Description=Configure 20G zstd-compressed zram swap (tier-0 before NVMe)
After=local-fs.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'swapoff /dev/zram0 2>/dev/null; zramctl --reset /dev/zram0 2>/dev/null; modprobe -r zram 2>/dev/null; modprobe zram && zramctl /dev/zram0 --size 20G --algorithm zstd && mkswap /dev/zram0 && swapon -p 100 /dev/zram0'
ExecStop=/bin/bash -c 'swapoff /dev/zram0 && zramctl --reset /dev/zram0'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable zram-swap.service
echo "  zram-swap.service enabled."

# (Re)start to pick up any size/algorithm changes
echo "  (Re)starting zram-swap..."
systemctl restart zram-swap.service

echo ""
echo "=== Done ==="
echo "Swap config summary:"
swapon --show
echo ""
sysctl vm.swappiness vm.page-cluster vm.vfs_cache_pressure vm.watermark_boost_factor vm.watermark_scale_factor
echo ""
echo "Both configs will persist across reboots."
echo "To undo: sudo systemctl disable --now zram-swap.service && sudo rm /etc/sysctl.d/99-nvme-swap.conf && sudo sysctl --system"
