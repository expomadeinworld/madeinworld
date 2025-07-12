# Order Service Kubernetes Deployment

This directory contains Kubernetes manifests for deploying the Order Service.

## Files

- `deployment.yaml` - Deployment configuration with 2 replicas
- `service.yaml` - Service configurations (ClusterIP and NodePort)
- `configmap.yaml` - Configuration values
- `secret.yaml` - Sensitive configuration (passwords, secrets)

## Prerequisites

1. Kubernetes cluster is running
2. PostgreSQL database is deployed and accessible
3. Auth service is deployed (for JWT validation)
4. Docker image `madeinworld/order-service:latest` is available

## Deployment Steps

1. **Create the namespace (optional):**
   ```bash
   kubectl create namespace madeinworld
   ```

2. **Update secrets:**
   ```bash
   # Edit secret.yaml with your actual base64-encoded values
   # Or create using kubectl:
   kubectl create secret generic order-service-secret \
     --from-literal=db-password=your-database-password \
     --from-literal=jwt-secret=your-jwt-secret
   ```

3. **Deploy the service:**
   ```bash
   kubectl apply -f configmap.yaml
   kubectl apply -f secret.yaml
   kubectl apply -f deployment.yaml
   kubectl apply -f service.yaml
   ```

4. **Verify deployment:**
   ```bash
   kubectl get pods -l app=order-service
   kubectl get services order-service
   ```

5. **Check logs:**
   ```bash
   kubectl logs -l app=order-service
   ```

## Service Access

- **Internal (ClusterIP):** `http://order-service:8082`
- **External (NodePort):** `http://<node-ip>:30082`

## Health Check

```bash
curl http://<service-url>:8082/health
```

## Configuration

Update `configmap.yaml` to modify service configuration. After changes:

```bash
kubectl apply -f configmap.yaml
kubectl rollout restart deployment/order-service
```

## Scaling

```bash
kubectl scale deployment order-service --replicas=3
```

## Troubleshooting

1. **Check pod status:**
   ```bash
   kubectl describe pod <pod-name>
   ```

2. **Check service endpoints:**
   ```bash
   kubectl get endpoints order-service
   ```

3. **View logs:**
   ```bash
   kubectl logs <pod-name>
   ```

4. **Test connectivity:**
   ```bash
   kubectl exec -it <pod-name> -- wget -qO- http://localhost:8082/health
   ```
