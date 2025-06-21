#!/bin/bash

# Verification script using AWS CLI (works without kubectl access)
# This script checks the deployment status using AWS services

set -e

echo "🔍 Verifying Made in World Catalog Service Deployment (AWS CLI method)"
echo "=================================================================="

# Set AWS profile
export AWS_PROFILE=madeinworld-frankfurt

echo ""
echo "📋 1. Verifying AWS credentials..."
aws sts get-caller-identity

echo ""
echo "🏗️  2. Checking EKS cluster status..."
CLUSTER_STATUS=$(aws eks describe-cluster --name madeinworld-dev-cluster --region eu-central-1 --query 'cluster.status' --output text)
echo "   Cluster Status: $CLUSTER_STATUS"

if [ "$CLUSTER_STATUS" != "ACTIVE" ]; then
    echo "❌ Cluster is not active. Current status: $CLUSTER_STATUS"
    exit 1
fi

echo ""
echo "🖼️  3. Verifying ECR image..."
ECR_REPO="834076182408.dkr.ecr.eu-central-1.amazonaws.com/madeinworld/catalog-service"
IMAGE_TAGS=$(aws ecr describe-images --repository-name madeinworld/catalog-service --region eu-central-1 --query 'imageDetails[*].imageTags' --output text 2>/dev/null || echo "")

if [ -n "$IMAGE_TAGS" ]; then
    echo "   ✅ ECR image found with tags: $IMAGE_TAGS"
    echo "   📦 Image URI: $ECR_REPO:latest"
else
    echo "   ❌ ECR image not found"
fi

echo ""
echo "🔗 4. Checking for Application Load Balancers..."
# Look for ALBs that might be created by the ingress
ALB_ARNS=$(aws elbv2 describe-load-balancers --region eu-central-1 --query 'LoadBalancers[?contains(LoadBalancerName, `k8s`) || contains(LoadBalancerName, `catalog`)].LoadBalancerArn' --output text 2>/dev/null || echo "")

if [ -n "$ALB_ARNS" ]; then
    echo "   ✅ Found potential ALBs:"
    for arn in $ALB_ARNS; do
        ALB_DNS=$(aws elbv2 describe-load-balancers --load-balancer-arns $arn --region eu-central-1 --query 'LoadBalancers[0].DNSName' --output text)
        ALB_STATE=$(aws elbv2 describe-load-balancers --load-balancer-arns $arn --region eu-central-1 --query 'LoadBalancers[0].State.Code' --output text)
        echo "     • DNS: $ALB_DNS (State: $ALB_STATE)"
    done
else
    echo "   ⏳ No ALBs found yet (may still be provisioning)"
fi

echo ""
echo "🗄️  5. Checking RDS database connectivity..."
RDS_ENDPOINT=$(aws rds describe-db-instances --region eu-central-1 --query 'DBInstances[?contains(DBInstanceIdentifier, `madeinworld`)].Endpoint.Address' --output text 2>/dev/null || echo "")

if [ -n "$RDS_ENDPOINT" ]; then
    echo "   ✅ RDS endpoint found: $RDS_ENDPOINT"
    
    # Test basic connectivity (this will fail if not in VPC, but that's expected)
    echo "   🔍 Testing database connectivity..."
    if timeout 5 bash -c "</dev/tcp/$RDS_ENDPOINT/5432" 2>/dev/null; then
        echo "   ✅ Database port is accessible"
    else
        echo "   ⏳ Database port not accessible from this location (expected if outside VPC)"
    fi
else
    echo "   ❌ RDS endpoint not found"
fi

echo ""
echo "🔐 6. Verifying AWS Secrets Manager..."
SECRET_VALUE=$(aws secretsmanager get-secret-value --secret-id madeinworld-db-password --region eu-central-1 --query 'SecretString' --output text 2>/dev/null || echo "")

if [ -n "$SECRET_VALUE" ]; then
    echo "   ✅ Database password secret found in Secrets Manager"
else
    echo "   ❌ Database password secret not found"
fi

echo ""
echo "📊 7. Summary of Deployment Readiness:"
echo "   =================================="

# Check each component
components_ready=0
total_components=4

if [ "$CLUSTER_STATUS" = "ACTIVE" ]; then
    echo "   ✅ EKS Cluster: Ready"
    ((components_ready++))
else
    echo "   ❌ EKS Cluster: Not Ready"
fi

if [ -n "$IMAGE_TAGS" ]; then
    echo "   ✅ Docker Image: Ready"
    ((components_ready++))
else
    echo "   ❌ Docker Image: Not Ready"
fi

if [ -n "$RDS_ENDPOINT" ]; then
    echo "   ✅ Database: Ready"
    ((components_ready++))
else
    echo "   ❌ Database: Not Ready"
fi

if [ -n "$SECRET_VALUE" ]; then
    echo "   ✅ Secrets: Ready"
    ((components_ready++))
else
    echo "   ❌ Secrets: Not Ready"
fi

echo ""
echo "📈 Readiness Score: $components_ready/$total_components components ready"

if [ $components_ready -eq $total_components ]; then
    echo "🎉 All infrastructure components are ready for deployment!"
    echo ""
    echo "🚀 Next Steps:"
    echo "   1. Resolve EKS cluster access (see EKS_ACCESS_TROUBLESHOOTING.md)"
    echo "   2. Run: ./deploy-complete.sh"
    echo "   3. Get ingress URL and update Flutter app"
else
    echo "⚠️  Some components are not ready. Please check the issues above."
fi

echo ""
echo "🔧 Manual Verification Commands:"
echo "   • Check cluster: aws eks describe-cluster --name madeinworld-dev-cluster --region eu-central-1"
echo "   • Check ECR: aws ecr describe-images --repository-name madeinworld/catalog-service --region eu-central-1"
echo "   • Check ALBs: aws elbv2 describe-load-balancers --region eu-central-1"
echo "   • Test kubectl: kubectl get nodes (requires cluster access)"
