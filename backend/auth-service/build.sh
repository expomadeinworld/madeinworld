#!/bin/bash

# Build script for auth-service
# This script builds the Docker image and pushes it to ECR

set -e

# Configuration
SERVICE_NAME="auth-service"
ECR_REGISTRY="834076182408.dkr.ecr.eu-central-1.amazonaws.com"
ECR_REPOSITORY="madeinworld/${SERVICE_NAME}"
AWS_REGION="eu-central-1"

# Get the current git commit hash for tagging
GIT_COMMIT=$(git rev-parse --short HEAD)
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
IMAGE_TAG="${TIMESTAMP}-${GIT_COMMIT}"

echo "Building ${SERVICE_NAME}..."
echo "Image tag: ${IMAGE_TAG}"

# Build the Docker image
echo "Building Docker image..."
docker build -t ${SERVICE_NAME}:${IMAGE_TAG} .
docker tag ${SERVICE_NAME}:${IMAGE_TAG} ${SERVICE_NAME}:latest

# Tag for ECR
docker tag ${SERVICE_NAME}:${IMAGE_TAG} ${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}
docker tag ${SERVICE_NAME}:${IMAGE_TAG} ${ECR_REGISTRY}/${ECR_REPOSITORY}:latest

echo "Docker image built successfully!"

# Login to ECR
echo "Logging in to ECR..."
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}

# Push to ECR
echo "Pushing to ECR..."
docker push ${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}
docker push ${ECR_REGISTRY}/${ECR_REPOSITORY}:latest

echo "Build completed!"
echo "Local images:"
echo "  ${SERVICE_NAME}:${IMAGE_TAG}"
echo "  ${SERVICE_NAME}:latest"
echo ""
echo "ECR images (ready to push):"
echo "  ${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}"
echo "  ${ECR_REGISTRY}/${ECR_REPOSITORY}:latest"
echo ""
echo "To push to ECR, uncomment the push commands in this script."
