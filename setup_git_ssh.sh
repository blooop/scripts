#!/bin/bash

ssh-keygen
cat ~/.ssh/id_ed25519.pub

sudo apt install -y git git-lfs

git config --global user.name "Austin Gregg-Smith"
git config --global user.email "blooop@gmail.com"
