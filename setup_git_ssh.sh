#!/bin/bash

ssh-keygen
cat ~/.ssh/id_rsa.pub

sudo apt install -y git

git config --global user.name "Austin Gregg-Smith"
git config --global user.email "blooop@gmail.com"