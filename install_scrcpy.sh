#!/bin/bash

set -e

INSTALL_DIR="$HOME/.local/share/scrcpy"
PLATFORM_TOOLS_DIR="$HOME/.local/share/platform-tools"

echo "Installing scrcpy and ADB platform-tools..."

# Create installation directory
mkdir -p "$INSTALL_DIR"
mkdir -p "$PLATFORM_TOOLS_DIR"

# Download and install ADB platform-tools if not already installed
if [ ! -f "$PLATFORM_TOOLS_DIR/adb" ]; then
    echo "Downloading Android platform-tools..."
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    wget -q --show-progress https://dl.google.com/android/repository/platform-tools-latest-linux.zip
    unzip -q platform-tools-latest-linux.zip
    cp -r platform-tools/* "$PLATFORM_TOOLS_DIR/"
    cd -
    rm -rf "$TEMP_DIR"
    echo "ADB platform-tools installed to $PLATFORM_TOOLS_DIR"
else
    echo "ADB already installed at $PLATFORM_TOOLS_DIR/adb"
fi

# Get the latest scrcpy release version
echo "Fetching latest scrcpy release..."
LATEST_VERSION=$(curl -s https://api.github.com/repos/Genymobile/scrcpy/releases/latest | grep '"tag_name"' | cut -d'"' -f4)

if [ -z "$LATEST_VERSION" ]; then
    echo "Failed to fetch latest version. Using default v3.3.3"
    LATEST_VERSION="v3.3.3"
fi

echo "Latest scrcpy version: $LATEST_VERSION"

# Download and install scrcpy
SCRCPY_URL="https://github.com/Genymobile/scrcpy/releases/download/${LATEST_VERSION}/scrcpy-linux-x86_64-${LATEST_VERSION}.tar.gz"

echo "Downloading scrcpy from $SCRCPY_URL..."
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"
wget -q --show-progress "$SCRCPY_URL"
tar -xzf "scrcpy-linux-x86_64-${LATEST_VERSION}.tar.gz"
rm -rf "$INSTALL_DIR"/*
cp -r scrcpy-linux-x86_64-${LATEST_VERSION}/* "$INSTALL_DIR/"
cd -
rm -rf "$TEMP_DIR"

echo "scrcpy installed to $INSTALL_DIR"

# Add to PATH if not already there
if ! grep -q "$PLATFORM_TOOLS_DIR" "$HOME/.bashrc"; then
    echo "" >> "$HOME/.bashrc"
    echo "# Android platform-tools (ADB)" >> "$HOME/.bashrc"
    echo "export PATH=\"\$PATH:\$HOME/.local/share/platform-tools\"" >> "$HOME/.bashrc"
    echo "Added platform-tools to PATH in ~/.bashrc"
fi

# Create a convenient wrapper script
WRAPPER_SCRIPT="$HOME/.local/bin/scrcpy"
mkdir -p "$HOME/.local/bin"
cat > "$WRAPPER_SCRIPT" << 'EOF'
#!/bin/bash
ADB="$HOME/.local/share/platform-tools/adb" "$HOME/.local/share/scrcpy/scrcpy" "$@"
EOF
chmod +x "$WRAPPER_SCRIPT"

echo ""
echo "Installation complete!"
echo "- ADB location: $PLATFORM_TOOLS_DIR/adb"
echo "- scrcpy location: $INSTALL_DIR/scrcpy"
echo "- Wrapper script: $WRAPPER_SCRIPT"
echo ""
echo "To use scrcpy, either:"
echo "  1. Run: scrcpy (if ~/.local/bin is in your PATH)"
echo "  2. Run: $WRAPPER_SCRIPT"
echo "  3. Restart your terminal and run: scrcpy"
echo ""
echo "Make sure USB debugging is enabled on your Android device!"
echo ""

# Run scrcpy
read -p "Do you want to run scrcpy now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    "$WRAPPER_SCRIPT"
fi
