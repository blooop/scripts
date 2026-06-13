#!/bin/bash

#global search as you type gui
sudo add-apt-repository ppa:christian-boxdoerfer/fsearch-stable -y
sudo apt update
sudo apt install fsearch

#disk space usage
#qml-module-* deps are required or the scan-view (MapPage.qml) fails to load and folders can't be scanned
sudo apt install -y filelight qml-module-qtquick-shapes qml-module-org-kde-kcoreaddons

#better file manager with tabs and inbuilt console
sudo apt install -y dolphin konsole 

