#!/bin/bash

ssh-keygen

sudo apt install -y git

git config --global user.name "Austin Gregg-Smith"
git config --global user.email "blooop@gmail.com"

cat ~/.ssh/id_ed25519.pub