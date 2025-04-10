#!/bin/bash

# Install necessary packages
sudo apt update

#set up pipewire for better bluetooth sound quality
#pulseaudio from https://gist.github.com/the-spyke/2de98b22ff4f978ebf0650c90e82027e

sudo apt install -y pipewire-media-session- wireplumber pipewire-audio-client-libraries
systemctl --user --now enable wireplumber.service 
sudo cp /usr/share/doc/pipewire/examples/alsa.conf.d/99-pipewire-default.conf /etc/alsa/conf.d/
sudo apt install -y libldacbt-{abr,enc}2 libspa-0.2-bluetooth pulseaudio-module-bluetooth-
#reboot now, afterwards check with cmd:
echo "REBOOT YOUR MACHINE NOW and then run:"
echo "LANG=C pactl info | grep '^Server Name'"
