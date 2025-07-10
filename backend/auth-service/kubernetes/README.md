# Auth Service Kubernetes Deployment

This directory contains Kubernetes manifests for deploying the auth-service to a Kubernetes cluster.

## Files

- `deployment.yaml` - Main deployment configuration with health checks and resource limits
- `service.yaml` - Service definitions for external and internal access
- `configmap.yaml` - Non-sensitive configuration values
- `secret.yaml` - Sensitive configuration (passwords, JWT secrets)

## Prerequisites

1. Kubernetes cluster with kubectl configured
2. Docker image built and pushed to ECR
3. Database accessible from the cluster
4. (Optional) External Secrets Operator for AWS Secrets Manager integration

## Deployment Steps

### 1. Build and Push Docker Image

```bash
# Build the image
./build.sh

# Push to ECR (uncomment push commands in build.sh)
# Make sure you're logged in to AWS ECR first
```

### 2. Create Secrets

**Option A: Manual Secret Creation**
```bash
# Create the secret with base64 encoded values
kubectl apply -f secret.yaml
```

**Option B: AWS Secrets Manager (Recommended for Production)**
```bash
# Install External Secrets Operator first
helm repo add external-secrets https://charts.external-secrets.io
helm install external-secrets external-secrets/external-secrets -n external-secrets-system --create-namespace

# Create AWS credentials secret
kubectl create secret generic aws-credentials \
  --from-literal=access-key-id=YOUR_ACCESS_KEY \
  --from-literal=secret-access-key=YOUR_SECRET_KEY

# Apply the external secret configuration
kubectl apply -f secret.yaml
```

### 3. Deploy the Service

```bash
# Apply all manifests
kubectl apply -f configmap.yaml
kubectl apply -f secret.yaml
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
```

### 4. Verify Deployment

```bash
# Check deployment status
kubectl get deployments
kubectl get pods -l app=auth-service

# Check service
kubectl get services auth-service

# Check logs
kubectl logs -l app=auth-service

# Test health endpoint
kubectl port-forward service/auth-service-internal 8081:8081
curl http://localhost:8081/health
```

## Configuration

### Environment Variables

The service uses the following environment variables:

**Database Configuration:**
- `DB_HOST` - Database hostname
- `DB_PORT` - Database port (default: 5432)
- `DB_USER` - Database username
- `DB_PASSWORD` - Database password (from secret)
- `DB_NAME` - Database name
- `DB_SSLMODE` - SSL mode (require/disable)

**Service Configuration:**
- `AUTH_PORT` - Service port (default: 8081)
- `GIN_MODE` - Gin framework mode (debug/release)

**JWT Configuration:**
- `JWT_SECRET` - Secret key for JWT signing (from secret)
- `JWT_EXPIRATION_HOURS` - Token expiration time in hours

### Resource Limits

The deployment includes resource requests and limits:
- **Requests:** 64Mi memory, 50m CPU
- **Limits:** 256Mi memory, 200m CPU

Adjust these based on your actual usage patterns.

### Health Checks

The deployment includes both liveness and readiness probes:
- **Liveness Probe:** Checks if the container is running
- **Readiness Probe:** Checks if the service is ready to accept traffic

Both probes use the `/health` endpoint.

## Security

The deployment follows security best practices:
- Runs as non-root user (UID 1001)
- Read-only root filesystem
- Drops all capabilities
- No privilege escalation

## Scaling

To scale the deployment:

```bash
kubectl scale deployment auth-service --replicas=3
```

## Troubleshooting

### Common Issues

1. **Pod not starting:**
   ```bash
   kubectl describe pod <pod-name>
   kubectl logs <pod-name>
   ```

2. **Database connection issues:**
   - Check if database is accessible from the cluster
   - Verify credentials in the secret
   - Check network policies

3. **Service not accessible:**
   ```bash
   kubectl get endpoints auth-service
   kubectl describe service auth-service
   ```

### Useful Commands

```bash
# Get all resources for auth-service
kubectl get all -l app=auth-service

# Delete all resources
kubectl delete -f .

# Watch pod status
kubectl get pods -l app=auth-service -w

# Port forward for local testing
kubectl port-forward service/auth-service-internal 8081:8081
```
