#!/bin/bash


# Ensure pixi is installed and in PATH
if ! command -v pixi &> /dev/null; then
	echo "pixi not found. Please run install_pixi.sh first or install pixi manually."
	exit 1
fi

# Install lazydocker using pixi
pixi global install lazydocker

echo "lazydocker installed via pixi. Run 'lazydocker' to start."
