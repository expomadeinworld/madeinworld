#!/bin/bash

# Build script for Order Service
# This script builds the order service binary and optionally creates a Docker image

set -e

echo "Building Order Service..."

# Clean previous builds
echo "Cleaning previous builds..."
rm -f order-service

# Get dependencies
echo "Getting dependencies..."
go mod tidy

# Run tests
echo "Running tests..."
go test ./...

# Build the binary
echo "Building binary..."
CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o order-service ./cmd/server

echo "Build completed successfully!"

# Check if Docker build is requested
if [ "$1" = "docker" ]; then
    echo "Building Docker image..."
    docker build -t madeinworld/order-service:latest .
    echo "Docker image built successfully!"
fi

echo "Order service build complete!"
echo "Binary: ./order-service"
if [ "$1" = "docker" ]; then
    echo "Docker image: madeinworld/order-service:latest"
fi
