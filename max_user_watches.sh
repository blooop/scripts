#!/bin/bash

# Desired maximum value
MAX_VALUE=524288
CONFIG_FILE="/etc/sysctl.conf"

# Check current value
CURRENT_VALUE=$(cat /proc/sys/fs/inotify/max_user_watches)
echo "Current max_user_watches value: $CURRENT_VALUE"

# If the current value is less than the desired maximum, update it
if [ "$CURRENT_VALUE" -lt "$MAX_VALUE" ]; then
    echo "Updating max_user_watches to $MAX_VALUE..."

    # Check if the setting already exists
    if grep -q "^fs.inotify.max_user_watches" "$CONFIG_FILE"; then
        sudo sed -i "s/^fs\.inotify\.max_user_watches.*/fs.inotify.max_user_watches=$MAX_VALUE/" "$CONFIG_FILE"
    else
        echo "fs.inotify.max_user_watches=$MAX_VALUE" | sudo tee -a "$CONFIG_FILE"
    fi

    # Apply the change immediately
    sudo sysctl -p

    echo "max_user_watches has been updated and applied."
else
    echo "No update needed. Current value is sufficient."
fi
