# EKS Access Troubleshooting Guide

## Current Issue
The current AWS user/role doesn't have access to the EKS cluster. This is a common issue when the cluster was created by a different user or when using SSO roles.

## Solution Options

### Option 1: Add Current User to Cluster Access (Recommended)
The cluster creator or an admin needs to add your current user to the cluster access:

```bash
# Get your current user ARN
aws sts get-caller-identity --profile madeinworld-frankfurt

# Add access entry (run by cluster admin)
aws eks create-access-entry \
  --cluster-name madeinworld-dev-cluster \
  --principal-arn "arn:aws:sts::834076182408:assumed-role/AWSReservedSSO_MadeInWorld-Admin_703cae4dc88782b6/madeinworld-admin" \
  --region eu-central-1

# Associate access policy (run by cluster admin)
aws eks associate-access-policy \
  --cluster-name madeinworld-dev-cluster \
  --principal-arn "arn:aws:sts::834076182408:assumed-role/AWSReservedSSO_MadeInWorld-Admin_703cae4dc88782b6/madeinworld-admin" \
  --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy \
  --access-scope type=cluster \
  --region eu-central-1
```

### Option 2: Update Cluster Authentication Mode
Change the cluster to use API mode for easier access management:

```bash
# Update cluster authentication mode (requires admin permissions)
aws eks update-cluster-config \
  --name madeinworld-dev-cluster \
  --access-config authenticationMode=API_AND_CONFIG_MAP \
  --region eu-central-1
```

### Option 3: Use Original Cluster Creator Credentials
If you have access to the original AWS credentials that created the cluster, use those:

```bash
# Switch to the original profile that created the cluster
export AWS_PROFILE=original-profile-name
kubectl get nodes
```

## Verification Steps

Once access is resolved, run these commands to verify:

```bash
# 1. Test cluster access
kubectl get nodes

# 2. Run the complete deployment
./deploy-complete.sh

# 3. Verify deployment status
kubectl get all -l app=catalog-service

# 4. Get ingress URL
kubectl get ingress catalog-service-ingress
```

## Alternative Verification Methods

If kubectl access cannot be resolved immediately, you can verify deployment through AWS Console:

1. **EKS Console**: Check cluster status and node groups
2. **EC2 Console**: Verify Load Balancer creation
3. **CloudWatch**: Check application logs
4. **ECR Console**: Confirm image was pushed successfully

## Current Status

✅ **Completed:**
- Docker image built and pushed to ECR
- Kubernetes manifests configured with correct values
- Database connection configured
- Flutter app updated with API endpoint

⏳ **Pending:**
- EKS cluster access resolution
- Kubernetes manifests deployment
- Ingress URL retrieval
- End-to-end testing

## Next Steps

1. Resolve EKS access using one of the options above
2. Run `./deploy-complete.sh` to deploy the application
3. Update Flutter app with the actual ingress URL
4. Test the complete integration
