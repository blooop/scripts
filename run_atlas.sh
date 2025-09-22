#!/bin/bash

# Atlas Network Discovery Tool Runner
# https://github.com/karam-ajaj/atlas?tab=readme-ov-file
# This script starts the Atlas Docker container and opens the UI in a browser

set -e

CONTAINER_NAME="atlas"
UI_URL="http://localhost:8888"

echo "🔍 Starting Atlas Network Discovery Tool..."

# Check if container already exists
if docker ps -a --format "table {{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
    echo "📦 Atlas container already exists"

    # Check if it's running
    if docker ps --format "table {{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
        echo "✅ Atlas is already running"
    else
        echo "🚀 Starting existing Atlas container..."
        docker start ${CONTAINER_NAME}
    fi
else
    echo "🚀 Creating and starting new Atlas container..."
    docker run -d \
      --name ${CONTAINER_NAME} \
      --network=host \
      --cap-add=NET_RAW \
      --cap-add=NET_ADMIN \
      -v /var/run/docker.sock:/var/run/docker.sock \
      keinstien/atlas:latest
fi

# Wait for the service to be ready
echo "⏳ Waiting for Atlas to be ready..."
for i in {1..30}; do
    if curl -s ${UI_URL} > /dev/null 2>&1; then
        echo "✅ Atlas is ready!"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "❌ Timeout waiting for Atlas to start"
        echo "📋 Container logs:"
        docker logs ${CONTAINER_NAME} --tail 20
        exit 1
    fi
    sleep 2
done

# Open browser
echo "🌐 Opening Atlas UI in browser..."
if command -v xdg-open > /dev/null; then
    xdg-open ${UI_URL}
elif command -v open > /dev/null; then
    open ${UI_URL}
elif command -v start > /dev/null; then
    start ${UI_URL}
else
    echo "📱 Please open ${UI_URL} in your browser"
fi

echo ""
echo "🎉 Atlas is running!"
echo "📊 UI Dashboard: ${UI_URL}"
echo "🏠 Hosts Table: ${UI_URL}/hosts.html"
echo "📖 API Docs: ${UI_URL}/api/docs"
echo ""
echo "To stop Atlas: docker stop ${CONTAINER_NAME}"
echo "To remove Atlas: docker rm ${CONTAINER_NAME}"