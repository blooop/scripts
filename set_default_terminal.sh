#!/bin/bash

set -e

if ! command -v terminator &>/dev/null; then
    echo "Error: terminator is not installed"
    exit 1
fi

mkdir -p ~/.config/xfce4

if [ -f ~/.config/xfce4/helpers.rc ]; then
    if grep -q '^TerminalEmulator=' ~/.config/xfce4/helpers.rc; then
        sed -i 's/^TerminalEmulator=.*/TerminalEmulator=terminator/' ~/.config/xfce4/helpers.rc
    else
        echo 'TerminalEmulator=terminator' >> ~/.config/xfce4/helpers.rc
    fi
else
    echo 'TerminalEmulator=terminator' > ~/.config/xfce4/helpers.rc
fi

echo "Default terminal set to terminator"
echo "Verify: exo-open --launch TerminalEmulator"
