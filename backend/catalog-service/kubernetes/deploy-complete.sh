#!/bin/bash

# Complete deployment script for Made in World Catalog Service
# This script deploys the catalog service to EKS and retrieves the ingress URL

set -e

echo "🚀 Starting deployment of Made in World Catalog Service..."

# Set AWS profile
export AWS_PROFILE=madeinworld-frankfurt

# Verify AWS credentials
echo "📋 Verifying AWS credentials..."
aws sts get-caller-identity

# Verify EKS cluster access
echo "🔍 Verifying EKS cluster access..."
kubectl get nodes

# Apply Kubernetes manifests in order
echo "📦 Applying Kubernetes manifests..."

echo "  ✅ Applying ConfigMap..."
kubectl apply -f configmap.yaml

echo "  🔐 Applying Secret..."
kubectl apply -f secret.yaml

echo "  🚀 Applying Deployment..."
kubectl apply -f deployment.yaml

echo "  🌐 Applying Service..."
kubectl apply -f service.yaml

echo "  🔗 Applying Ingress..."
kubectl apply -f ingress.yaml

# Wait for deployment to be ready
echo "⏳ Waiting for deployment to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/catalog-service

# Check pod status
echo "📊 Checking pod status..."
kubectl get pods -l app=catalog-service

# Get service status
echo "🌐 Checking service status..."
kubectl get service catalog-service

# Wait for ingress to be ready and get URL
echo "🔗 Waiting for ingress to be ready..."
echo "This may take a few minutes as AWS provisions the Application Load Balancer..."

# Function to get ingress URL
get_ingress_url() {
    kubectl get ingress catalog-service-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo ""
}

# Wait for ingress URL (up to 10 minutes)
TIMEOUT=600
ELAPSED=0
INTERVAL=30

while [ $ELAPSED -lt $TIMEOUT ]; do
    INGRESS_URL=$(get_ingress_url)
    if [ -n "$INGRESS_URL" ]; then
        echo "✅ Ingress URL ready: https://$INGRESS_URL"
        break
    fi
    echo "⏳ Waiting for ingress URL... (${ELAPSED}s/${TIMEOUT}s)"
    sleep $INTERVAL
    ELAPSED=$((ELAPSED + INTERVAL))
done

if [ -z "$INGRESS_URL" ]; then
    echo "⚠️  Timeout waiting for ingress URL. Check ingress status manually:"
    echo "   kubectl get ingress catalog-service-ingress"
    echo "   kubectl describe ingress catalog-service-ingress"
else
    echo ""
    echo "🎉 Deployment completed successfully!"
    echo ""
    echo "📋 Deployment Summary:"
    echo "   • Docker Image: 834076182408.dkr.ecr.eu-central-1.amazonaws.com/madeinworld/catalog-service:latest"
    echo "   • Ingress URL: https://$INGRESS_URL"
    echo "   • API Base URL: https://$INGRESS_URL/api/v1"
    echo ""
    echo "🔧 Next Steps:"
    echo "   1. Update Flutter app API URL to: https://$INGRESS_URL"
    echo "   2. Test API endpoints:"
    echo "      • Health: https://$INGRESS_URL/health"
    echo "      • Products: https://$INGRESS_URL/api/v1/products"
    echo "      • Categories: https://$INGRESS_URL/api/v1/categories"
    echo "      • Stores: https://$INGRESS_URL/api/v1/stores"
    echo ""
fi

# Show final status
echo "📊 Final Status:"
kubectl get all -l app=catalog-service
echo ""
kubectl get ingress catalog-service-ingress
