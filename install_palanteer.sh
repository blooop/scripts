#!/bin/bash

set -e

echo "Installing Palanteer dependencies..."
sudo apt-get update && sudo apt-get install -y --no-install-recommends \
    build-essential libgl1-mesa-dev libxrender-dev git cmake ca-certificates python3-dev python3-setuptools python3-wheel 

echo "Cloning and building Palanteer..."
git clone https://github.com/dfeneyrou/palanteer.git
cd palanteer
mkdir build
cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j$(nproc) install
sudo cp bin/palanteer /usr/local/bin/
cd ../..
rm -rf ./palanteer

echo "Palanteer installation complete!"