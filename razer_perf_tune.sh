#!/usr/bin/env bash
# razer_perf_tune.sh — Performance tuning for Razer Blade (i9-13950HX / RTX 4090)
# Ubuntu 24.04 on NVMe with heavy dev workloads (Docker, VS Code, Chrome, Claude)
#
# Run with: razer_perf_tune.sh
# Undo with: razer_perf_tune.sh --undo
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    exec sudo "$0" "$@"
fi

SYSCTL_CONF="/etc/sysctl.d/99-razer-perf.conf"
OLD_SYSCTL_CONF="/etc/sysctl.d/99-nvme-swap.conf"
SYSTEMD_UNIT="/etc/systemd/system/razer-perf-tune.service"

undo() {
    echo "=== Reverting all changes ==="

    if [[ -f "$SYSCTL_CONF" ]]; then
        rm "$SYSCTL_CONF"
        echo "  Removed $SYSCTL_CONF"
    fi
    sysctl --system > /dev/null 2>&1

    echo N > /sys/module/zswap/parameters/enabled
    echo 0 > /sys/devices/system/cpu/intel_pstate/hwp_dynamic_boost

    powerprofilesctl set balanced
    echo "  Power profile set to balanced"

    if [[ -f "$SYSTEMD_UNIT" ]]; then
        systemctl disable --now razer-perf-tune.service 2>/dev/null
        rm "$SYSTEMD_UNIT"
        echo "  Removed systemd unit"
    fi

    rm -rf /etc/systemd/system/docker.service.d/nice.conf \
           /etc/systemd/system/containerd.service.d/nice.conf
    systemctl daemon-reload
    echo "  Removed systemd drop-ins"

    for pid in $(pgrep -x Xorg 2>/dev/null); do
        chrt -o -p 0 "$pid" 2>/dev/null
    done
    echo "  Xorg reverted to default scheduling"

    echo "=== Reverted to defaults ==="
    echo "NOTE: fstab noatime change must be reverted manually if applied."
    exit 0
}

if [[ "${1:-}" == "--undo" ]]; then
    undo
fi

echo "=== Razer Blade Performance Tuning ==="
echo "  CPU: $(grep 'model name' /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)"
echo "  RAM: $(free -h | awk '/Mem:/{print $2}')"
echo "  GPU: $(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null || echo 'unknown')"
echo ""

# ─── 1. Power profile ──────────────────────────────────────────────────────────
# "balanced" caps CPU boost. On AC power with this workload, run wide open.
echo "=== 1. Setting power profile to performance ==="
powerprofilesctl set performance
echo "  Done. (was: balanced)"

# ─── 2. HWP dynamic boost ──────────────────────────────────────────────────────
# Lets the CPU opportunistically boost higher on lightly-threaded work (UI, builds).
echo "=== 2. Enabling HWP dynamic boost ==="
echo 1 > /sys/devices/system/cpu/intel_pstate/hwp_dynamic_boost
echo "  Done."

# ─── 3. Re-enable zswap ────────────────────────────────────────────────────────
# Ubuntu 24.04's swappiness=100 is designed around zswap being active.
# Without zswap, every swap-out goes straight to NVMe — adds I/O wait.
# With zswap, idle pages compress in RAM first (typical 3:1 ratio),
# only spilling to disk when the pool fills.
echo "=== 3. Enabling zswap (lz4, 25% pool) ==="
echo lz4 > /sys/module/zswap/parameters/compressor   # faster than default lzo
echo 25  > /sys/module/zswap/parameters/max_pool_percent
echo Y   > /sys/module/zswap/parameters/enabled
echo "  Done. (compressor=lz4, max_pool=25%)"

# ─── 4. Sysctl tuning ──────────────────────────────────────────────────────────
echo "=== 4. Installing sysctl tuning ==="

# Clean up old config from setup_swap.sh
if [[ -f "$OLD_SYSCTL_CONF" ]]; then
    rm "$OLD_SYSCTL_CONF"
    echo "  Removed stale $OLD_SYSCTL_CONF"
fi

tee "$SYSCTL_CONF" > /dev/null <<'EOF'
# Razer Blade perf tuning — Ubuntu 24.04 + NVMe + zswap

# With zswap active, 100 is correct: "swap" first means compress-in-RAM,
# which frees pages for file cache without disk I/O.
vm.swappiness = 100

# Single-page swap I/O — NVMe random access is fast, no need to batch.
vm.page-cluster = 0

# Default cache pressure is fine — Docker builds benefit from dentry/inode cache.
vm.vfs_cache_pressure = 100

# NVMe can flush fast — let more dirty pages accumulate before writeback.
# Reduces small-write I/O from Docker overlay and build tools.
vm.dirty_ratio = 30
vm.dirty_background_ratio = 5

# Increase inotify limits — VS Code, Docker, and file watchers eat these up.
fs.inotify.max_user_watches = 1048576
fs.inotify.max_user_instances = 8192

# Scheduler: favor interactive/UI responsiveness over throughput.
# Lower latency = more frequent preemption of background work.
kernel.sched_latency_ns = 4000000
kernel.sched_min_granularity_ns = 500000
kernel.sched_wakeup_granularity_ns = 500000
EOF

sysctl --system > /dev/null 2>&1
echo "  Installed $SYSCTL_CONF"

# ─── 5. Filesystem: noatime ────────────────────────────────────────────────────
# Every file read updates the access timestamp — pointless write I/O on a workstation.
echo "=== 5. Checking fstab for noatime ==="
if grep -qE '^\S+\s+/\s+ext4\s+defaults' /etc/fstab && ! grep -qE '^\S+\s+/\s+ext4\s+.*noatime' /etc/fstab; then
    sed -i.bak 's|^\(\S\+\s\+/\s\+ext4\s\+\)defaults|\1defaults,noatime|' /etc/fstab
    systemctl daemon-reload
    mount -o remount,noatime /
    echo "  Added noatime to / and remounted. Backup at /etc/fstab.bak"
elif grep -qE '^\S+\s+/\s+ext4\s+.*noatime' /etc/fstab; then
    echo "  Already has noatime, skipping."
else
    echo "  Root mount not matched — check /etc/fstab manually."
fi

# ─── 6. NVIDIA persistence ─────────────────────────────────────────────────────
# Keeps the GPU initialized so the first CUDA/graphics call doesn't stall.
echo "=== 6. Checking NVIDIA persistence mode ==="
if systemctl is-active --quiet nvidia-persistenced; then
    echo "  nvidia-persistenced already running."
else
    nvidia-smi -pm 1 2>/dev/null && echo "  Enabled persistence mode." || echo "  Skipped (not available)."
fi

# ─── 7. Process priorities ────────────────────────────────────────────────────
# Boost UI processes, nice down background hogs so the desktop stays responsive.
echo "=== 7. Setting process priorities ==="

# Boost: Xorg gets real-time FIFO scheduling so it never waits behind CPU hogs
for pid in $(pgrep -x Xorg 2>/dev/null); do
    chrt -r -p 10 "$pid" 2>/dev/null && echo "  Xorg (PID $pid) → SCHED_RR pri 10"
done

# Nice down heavy background work: Docker, Claude, Sim, containerd
for name in claude containerd dockerd Sim; do
    for pid in $(pgrep -x "$name" 2>/dev/null); do
        renice 10 -p "$pid" > /dev/null 2>&1
        ionice -c 2 -n 6 -p "$pid" 2>/dev/null
    done
    count=$(pgrep -cx "$name" 2>/dev/null || echo 0)
    [[ "$count" -gt 0 ]] && echo "  $name ($count procs) → nice 10, ionice best-effort/6"
done

# Install udev-style persistent rules via systemd drop-in for Docker/containerd
mkdir -p /etc/systemd/system/docker.service.d
tee /etc/systemd/system/docker.service.d/nice.conf > /dev/null <<'EOF'
[Service]
Nice=10
IOSchedulingClass=best-effort
IOSchedulingPriority=6
EOF

mkdir -p /etc/systemd/system/containerd.service.d
tee /etc/systemd/system/containerd.service.d/nice.conf > /dev/null <<'EOF'
[Service]
Nice=10
IOSchedulingClass=best-effort
IOSchedulingPriority=6
EOF
echo "  Docker/containerd systemd drop-ins installed (nice 10 on restart)"

# ─── 8. Systemd unit for boot persistence ─────────────────────────────────────
# Power profile, HWP boost, and zswap params live in sysfs — reset every reboot.
# This oneshot service re-applies them early in boot.
echo "=== 8. Installing systemd boot service ==="
tee "$SYSTEMD_UNIT" > /dev/null <<'EOF'
[Unit]
Description=Razer Blade performance tuning (power profile, HWP boost, zswap, Xorg priority)
After=power-profiles-daemon.service display-manager.service

[Service]
Type=oneshot
ExecStart=/bin/bash -c '\
    powerprofilesctl set performance && \
    echo 1 > /sys/devices/system/cpu/intel_pstate/hwp_dynamic_boost && \
    echo lz4 > /sys/module/zswap/parameters/compressor && \
    echo 25  > /sys/module/zswap/parameters/max_pool_percent && \
    echo Y   > /sys/module/zswap/parameters/enabled && \
    sleep 2 && \
    for pid in $(pgrep -x Xorg); do chrt -r -p 10 $pid; done'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable razer-perf-tune.service > /dev/null 2>&1
echo "  Installed and enabled $SYSTEMD_UNIT"

# ─── 9. Summary ────────────────────────────────────────────────────────────────
echo ""
echo "=== Summary ==="
echo "  Power profile : $(powerprofilesctl get)"
echo "  HWP dyn boost : $(cat /sys/devices/system/cpu/intel_pstate/hwp_dynamic_boost)"
echo "  zswap enabled : $(cat /sys/module/zswap/parameters/enabled) (compressor=$(cat /sys/module/zswap/parameters/compressor), pool=$(cat /sys/module/zswap/parameters/max_pool_percent)%)"
echo "  swappiness    : $(sysctl -n vm.swappiness)"
echo "  page-cluster  : $(sysctl -n vm.page-cluster)"
echo "  dirty_ratio   : $(sysctl -n vm.dirty_ratio) / bg=$(sysctl -n vm.dirty_background_ratio)"
echo "  inotify       : watches=$(sysctl -n fs.inotify.max_user_watches) instances=$(sysctl -n fs.inotify.max_user_instances)"
echo "  noatime       : $(mount | grep 'on / ' | grep -q noatime && echo 'yes' || echo 'no')"
echo "  CPU freq      : $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq)kHz / $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq)kHz max"
echo "  CPU temp      : $(sensors 2>/dev/null | grep 'Core 0:' | awk '{print $3}' || echo 'unknown')"
echo ""
echo "All settings persist across reboots (sysctl + fstab + systemd unit)."
echo "Undo everything: $0 --undo"
