#!/bin/bash

# Build script for catalog-service Docker image

set -e

# Configuration
IMAGE_NAME="madeinworld/catalog-service"
TAG=${1:-latest}
REGISTRY=${REGISTRY:-""}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Building catalog-service Docker image...${NC}"

# Build the Docker image
docker build -t ${IMAGE_NAME}:${TAG} .

echo -e "${GREEN}✓ Docker image built successfully: ${IMAGE_NAME}:${TAG}${NC}"

# Tag for registry if specified
if [ ! -z "$REGISTRY" ]; then
    FULL_IMAGE_NAME="${REGISTRY}/${IMAGE_NAME}:${TAG}"
    docker tag ${IMAGE_NAME}:${TAG} ${FULL_IMAGE_NAME}
    echo -e "${GREEN}✓ Tagged for registry: ${FULL_IMAGE_NAME}${NC}"
fi

# Show image info
echo -e "${YELLOW}Image information:${NC}"
docker images ${IMAGE_NAME}:${TAG}

echo -e "${YELLOW}Usage examples:${NC}"
echo "  Run locally:"
echo "    docker run -p 8080:8080 --env-file .env ${IMAGE_NAME}:${TAG}"
echo ""
echo "  Push to registry (if tagged):"
if [ ! -z "$REGISTRY" ]; then
    echo "    docker push ${FULL_IMAGE_NAME}"
else
    echo "    Set REGISTRY environment variable and rebuild"
fi
echo ""
echo "  Test the container:"
echo "    docker run -d --name catalog-test -p 8080:8080 --env-file .env ${IMAGE_NAME}:${TAG}"
echo "    curl http://localhost:8080/health"
echo "    docker stop catalog-test && docker rm catalog-test"
