#!/usr/bin/env bash
# setup-swap.sh — 32G NVMe swapfile with moderate tuning
# Run with: sudo bash setup_swap.sh
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Error: must run as root (sudo $0)"
    exit 1
fi

SWAPFILE="/swap.img"
SWAPFILE_SIZE="32G"

echo "=== Resizing swapfile to ${SWAPFILE_SIZE} ==="
if swapon --show | grep -q "$SWAPFILE"; then
    swapoff "$SWAPFILE"
    echo "  Disabled existing swapfile."
fi
fallocate -l "$SWAPFILE_SIZE" "$SWAPFILE"
chmod 600 "$SWAPFILE"
mkswap "$SWAPFILE"
swapon "$SWAPFILE"
echo "  Swapfile active at ${SWAPFILE_SIZE}."

echo ""
echo "=== Installing sysctl tuning ==="
tee /etc/sysctl.d/99-nvme-swap.conf <<'EOF'
# NVMe swap tuning — keep app pages resident, swap only under real pressure
vm.swappiness=10
vm.page-cluster=0
vm.vfs_cache_pressure=100
EOF
sysctl --system
echo "  sysctl params installed and loaded."

echo ""
echo "=== Disabling zram if previously enabled ==="
if systemctl is-enabled zram-swap.service &>/dev/null; then
    systemctl disable --now zram-swap.service
    rm -f /etc/systemd/system/zram-swap.service
    systemctl daemon-reload
    echo "  zram-swap.service removed."
else
    echo "  No zram-swap.service found, skipping."
fi

echo ""
echo "=== Done ==="
echo "Swap config summary:"
swapon --show
echo ""
sysctl vm.swappiness vm.page-cluster vm.vfs_cache_pressure
echo ""
echo "Configs persist across reboots."
echo "To undo: sudo swapoff ${SWAPFILE} && sudo rm /etc/sysctl.d/99-nvme-swap.conf && sudo sysctl --system"
