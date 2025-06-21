#!/bin/bash

# Deployment script for catalog-service on EKS

set -e

# Configuration
NAMESPACE=${NAMESPACE:-default}
CONTEXT=${CONTEXT:-}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

log_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

log_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl is not installed"
        exit 1
    fi
    
    if ! kubectl cluster-info &> /dev/null; then
        log_error "kubectl is not connected to a cluster"
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

# Set kubectl context if specified
set_context() {
    if [ ! -z "$CONTEXT" ]; then
        log_info "Setting kubectl context to $CONTEXT"
        kubectl config use-context $CONTEXT
    fi
}

# Create namespace if it doesn't exist
create_namespace() {
    if ! kubectl get namespace $NAMESPACE &> /dev/null; then
        log_info "Creating namespace $NAMESPACE"
        kubectl create namespace $NAMESPACE
        log_success "Namespace $NAMESPACE created"
    else
        log_info "Namespace $NAMESPACE already exists"
    fi
}

# Deploy resources
deploy_resources() {
    log_info "Deploying catalog-service resources..."
    
    # Apply ConfigMap
    log_info "Applying ConfigMap..."
    kubectl apply -f configmap.yaml -n $NAMESPACE
    log_success "ConfigMap applied"
    
    # Apply Secret (manual for now, External Secrets Operator for production)
    log_warning "Please ensure the secret is properly configured with the database password"
    kubectl apply -f secret.yaml -n $NAMESPACE
    log_success "Secret applied"
    
    # Apply Deployment
    log_info "Applying Deployment..."
    kubectl apply -f deployment.yaml -n $NAMESPACE
    log_success "Deployment applied"
    
    # Apply Service
    log_info "Applying Service..."
    kubectl apply -f service.yaml -n $NAMESPACE
    log_success "Service applied"
    
    # Apply Ingress (optional)
    if [ "$1" = "--with-ingress" ]; then
        log_info "Applying Ingress..."
        kubectl apply -f ingress.yaml -n $NAMESPACE
        log_success "Ingress applied"
    else
        log_warning "Skipping Ingress deployment. Use --with-ingress to deploy it."
    fi
}

# Wait for deployment to be ready
wait_for_deployment() {
    log_info "Waiting for deployment to be ready..."
    kubectl rollout status deployment/catalog-service -n $NAMESPACE --timeout=300s
    log_success "Deployment is ready"
}

# Show deployment status
show_status() {
    log_info "Deployment status:"
    echo ""
    
    echo "Pods:"
    kubectl get pods -l app=catalog-service -n $NAMESPACE
    echo ""
    
    echo "Services:"
    kubectl get services -l app=catalog-service -n $NAMESPACE
    echo ""
    
    echo "Ingress:"
    kubectl get ingress -l app=catalog-service -n $NAMESPACE 2>/dev/null || echo "No ingress found"
    echo ""
    
    # Get LoadBalancer URL
    LB_URL=$(kubectl get service catalog-service -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
    if [ ! -z "$LB_URL" ]; then
        log_success "LoadBalancer URL: http://$LB_URL"
        log_info "Test the service: curl http://$LB_URL/health"
    else
        log_warning "LoadBalancer URL not yet available. Check again in a few minutes."
    fi
}

# Main execution
main() {
    echo -e "${YELLOW}Deploying catalog-service to EKS cluster${NC}"
    echo "Namespace: $NAMESPACE"
    echo ""
    
    check_prerequisites
    set_context
    create_namespace
    deploy_resources $1
    wait_for_deployment
    show_status
    
    log_success "Deployment completed successfully!"
}

# Help function
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --with-ingress    Deploy with Ingress resource"
    echo "  --help           Show this help message"
    echo ""
    echo "Environment variables:"
    echo "  NAMESPACE        Kubernetes namespace (default: default)"
    echo "  CONTEXT          Kubectl context to use"
    echo ""
    echo "Examples:"
    echo "  $0                           # Deploy without ingress"
    echo "  $0 --with-ingress           # Deploy with ingress"
    echo "  NAMESPACE=production $0     # Deploy to production namespace"
}

# Parse arguments
case "$1" in
    --help)
        show_help
        exit 0
        ;;
    *)
        main $1
        ;;
esac
