#!/bin/bash
set -e

INSTALL_DIR="${HOME}/filestash"

echo "Installing Filestash to ${INSTALL_DIR}..."

# Create directory
mkdir -p "${INSTALL_DIR}"
cd "${INSTALL_DIR}"

# Download docker-compose.yml
echo "Downloading docker-compose.yml..."
curl -O https://downloads.filestash.app/latest/docker-compose.yml

# Start the service
echo "Starting Filestash..."
docker compose up -d

echo ""
echo "Filestash is now running!"
echo "Opening http://localhost:8334 in browser..."
echo ""
echo "To stop:    cd ${INSTALL_DIR} && docker compose down"
echo "To upgrade: cd ${INSTALL_DIR} && curl -O https://downloads.filestash.app/latest/docker-compose.yml && docker compose pull && docker compose up -d"

# Wait for container to be ready, then open browser
sleep 2
xdg-open "http://localhost:8334" 2>/dev/null &
