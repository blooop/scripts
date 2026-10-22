#!/usr/bin/env bash
# Start Claude Code Remote Control at boot as a systemd user service.
# Usage: install_claude_remote_control.sh [working-dir]   (default: $HOME)
set -euo pipefail

workdir="$(realpath "${1:-$HOME}")"
claude_bin="$HOME/.local/bin/claude"
unit="$HOME/.config/systemd/user/claude-remote-control.service"

if [ ! -x "$claude_bin" ]; then
    echo "Claude is not installed at $claude_bin. Run install_claude.sh first." >&2
    exit 1
fi

echo "Writing $unit..."
mkdir -p "$(dirname "$unit")"
cat > "$unit" <<EOF
[Unit]
Description=Claude Code Remote Control
After=network-online.target
Wants=network-online.target

[Service]
WorkingDirectory=$workdir
ExecStart=$claude_bin remote-control --name %H
Restart=on-failure
RestartSec=30

[Install]
WantedBy=default.target
EOF

echo "Enabling and starting the service..."
systemctl --user daemon-reload
systemctl --user enable claude-remote-control.service
systemctl --user restart claude-remote-control.service

# Start user services at boot, before login
echo "Enabling linger for $USER..."
loginctl enable-linger "$USER"

echo "Service status:"
systemctl --user --no-pager status claude-remote-control.service || true
echo
echo "Follow the log (shows the session URL):"
echo "  journalctl --user -u claude-remote-control -f"
