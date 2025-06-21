# Kubernetes Deployment for Catalog Service

This directory contains Kubernetes manifests for deploying the catalog-service to an EKS cluster.

## Files

- `configmap.yaml` - Configuration data (database connection, etc.)
- `secret.yaml` - Sensitive data (database password)
- `deployment.yaml` - Application deployment configuration
- `service.yaml` - Service definitions (LoadBalancer and ClusterIP)
- `ingress.yaml` - Ingress configuration for external access
- `deploy.sh` - Automated deployment script
- `README.md` - This documentation

## Prerequisites

1. **EKS cluster** provisioned and accessible
2. **kubectl** configured to connect to the cluster
3. **AWS Load Balancer Controller** installed (for ingress)
4. **External Secrets Operator** (optional, for AWS Secrets Manager integration)
5. **Docker image** built and pushed to a registry

## Quick Deployment

### 1. Update Configuration

Edit `configmap.yaml` to set the correct RDS endpoint:

```yaml
data:
  DB_HOST: "your-rds-endpoint.eu-central-2.rds.amazonaws.com"
```

### 2. Set Database Password

**Option A: Manual Secret (for testing)**
```bash
# Encode your password
echo -n "your_password" | base64

# Edit secret.yaml and add the encoded password
kubectl apply -f secret.yaml
```

**Option B: AWS Secrets Manager (recommended)**
```bash
# Install External Secrets Operator first
helm repo add external-secrets https://charts.external-secrets.io
helm install external-secrets external-secrets/external-secrets -n external-secrets-system --create-namespace

# Apply the secret configuration
kubectl apply -f secret.yaml
```

### 3. Update Image Reference

Edit `deployment.yaml` to reference your Docker image:

```yaml
image: your-registry/madeinworld/catalog-service:latest
```

### 4. Deploy

```bash
# Deploy without ingress
./deploy.sh

# Deploy with ingress
./deploy.sh --with-ingress
```

## Manual Deployment

If you prefer to deploy manually:

```bash
# Create namespace (if needed)
kubectl create namespace default

# Apply resources in order
kubectl apply -f configmap.yaml
kubectl apply -f secret.yaml
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f ingress.yaml  # optional

# Check deployment status
kubectl get pods -l app=catalog-service
kubectl get services -l app=catalog-service
```

## Configuration Details

### ConfigMap
Contains non-sensitive configuration:
- Database connection details (host, port, user, database name)
- Application settings (port, mode)

### Secret
Contains sensitive data:
- Database password (base64 encoded)
- Can be integrated with AWS Secrets Manager for automatic rotation

### Deployment
- **Replicas**: 2 for high availability
- **Resources**: Optimized for small workloads (can be scaled up)
- **Health checks**: Liveness and readiness probes on `/health`
- **Security**: Non-root user, read-only filesystem, dropped capabilities

### Service
- **LoadBalancer**: External access via AWS Network Load Balancer
- **ClusterIP**: Internal cluster communication

### Ingress
- **AWS ALB**: Application Load Balancer with SSL termination
- **CORS**: Enabled for cross-origin requests
- **Health checks**: Configured for `/health` endpoint

## Scaling

### Horizontal Scaling
```bash
kubectl scale deployment catalog-service --replicas=5
```

### Vertical Scaling
Edit `deployment.yaml` to increase resource limits:
```yaml
resources:
  limits:
    memory: "512Mi"
    cpu: "500m"
```

## Monitoring

### Check Pod Status
```bash
kubectl get pods -l app=catalog-service
kubectl describe pod <pod-name>
```

### View Logs
```bash
kubectl logs -l app=catalog-service
kubectl logs -f deployment/catalog-service  # follow logs
```

### Health Check
```bash
# Get LoadBalancer URL
LB_URL=$(kubectl get service catalog-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# Test health endpoint
curl http://$LB_URL/health

# Test API endpoint
curl http://$LB_URL/api/v1/products
```

## Troubleshooting

### Common Issues

1. **Pods not starting**
   ```bash
   kubectl describe pod <pod-name>
   kubectl logs <pod-name>
   ```

2. **Database connection issues**
   - Check RDS endpoint in ConfigMap
   - Verify database password in Secret
   - Ensure security groups allow EKS to RDS communication

3. **LoadBalancer not getting external IP**
   - Check AWS Load Balancer Controller is installed
   - Verify IAM permissions for the controller
   - Check service annotations

4. **Ingress not working**
   - Ensure AWS Load Balancer Controller is installed
   - Check certificate ARN in ingress annotations
   - Verify domain DNS configuration

### Debug Commands
```bash
# Check all resources
kubectl get all -l app=catalog-service

# Check events
kubectl get events --sort-by=.metadata.creationTimestamp

# Check ingress details
kubectl describe ingress catalog-service-ingress

# Test internal connectivity
kubectl run debug --image=busybox -it --rm -- sh
# Inside the pod: wget -qO- http://catalog-service-internal:8080/health
```

## Security Considerations

- **Non-root containers**: All containers run as non-root user
- **Read-only filesystem**: Prevents runtime modifications
- **Resource limits**: Prevents resource exhaustion
- **Network policies**: Consider implementing for additional isolation
- **Secret management**: Use AWS Secrets Manager for production

## Production Recommendations

1. **Use External Secrets Operator** for secret management
2. **Implement network policies** for pod-to-pod communication
3. **Set up monitoring** with Prometheus and Grafana
4. **Configure log aggregation** with ELK stack or CloudWatch
5. **Implement backup strategies** for persistent data
6. **Use GitOps** for deployment automation (ArgoCD, Flux)
7. **Set up alerts** for service health and performance metrics

## Cleanup

To remove all resources:

```bash
kubectl delete -f .
```

Or delete specific resources:
```bash
kubectl delete deployment catalog-service
kubectl delete service catalog-service
kubectl delete ingress catalog-service-ingress
kubectl delete configmap catalog-service-config
kubectl delete secret catalog-service-secret
```
