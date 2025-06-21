# Made in World - Terraform Infrastructure

This directory contains the Terraform configuration for provisioning the AWS infrastructure for the Made in World application.

## Prerequisites

1. **AWS CLI configured** with appropriate credentials
2. **Terraform installed** (version >= 1.0)
3. **Database password secret created** in AWS Secrets Manager

## Setup Instructions

### 1. Create Database Password Secret

Before running Terraform, you need to create a secret in AWS Secrets Manager for the database password:

```bash
# Create the secret with a secure password
aws secretsmanager create-secret \
    --name "madeinworld-db-password" \
    --description "Database password for Made in World application" \
    --secret-string '{"password":"YOUR_SECURE_PASSWORD_HERE"}' \
    --region eu-central-2
```

Replace `YOUR_SECURE_PASSWORD_HERE` with a strong password.

### 2. Initialize Terraform

```bash
cd terraform
terraform init
```

### 3. Plan the Infrastructure

```bash
terraform plan
```

Review the planned changes to ensure everything looks correct.

### 4. Apply the Infrastructure

```bash
terraform apply
```

Type `yes` when prompted to confirm the creation of resources.

## Infrastructure Components

This Terraform configuration creates:

### Networking
- **VPC** with DNS support enabled
- **Public subnets** (2) for load balancers and NAT gateways
- **Private subnets** (2) for EKS nodes and RDS
- **Internet Gateway** for public internet access
- **NAT Gateways** (2) for private subnet internet access
- **Route tables** and associations

### Database
- **RDS PostgreSQL instance** (db.t3.micro)
- **DB subnet group** spanning private subnets
- **Security group** allowing PostgreSQL access from EKS nodes only

### Kubernetes
- **EKS cluster** with public and private endpoint access
- **EKS node group** with 2 t3.medium instances (scalable 1-4)
- **IAM roles** and policies for cluster and nodes
- **Security groups** for cluster and node communication

### Security
- **Security groups** with least-privilege access
- **IAM roles** following AWS best practices
- **Database password** stored in AWS Secrets Manager

## Configuration Variables

Key variables you can customize in `variables.tf`:

- `aws_region`: AWS region (default: eu-central-2)
- `project_name`: Project name (default: madeinworld)
- `environment`: Environment name (default: dev)
- `db_instance_class`: RDS instance size (default: db.t3.micro)
- `eks_node_instance_types`: EKS node instance types (default: t3.medium)

## Outputs

After successful deployment, Terraform will output:

- VPC and subnet IDs
- RDS endpoint and connection details
- EKS cluster endpoint and configuration
- Security group IDs

## Next Steps

After infrastructure is provisioned:

1. **Configure kubectl** to connect to the EKS cluster:
   ```bash
   aws eks update-kubeconfig --region eu-central-2 --name madeinworld-dev-cluster
   ```

2. **Verify cluster access**:
   ```bash
   kubectl get nodes
   ```

3. **Install AWS Load Balancer Controller** (for ingress):
   ```bash
   # Follow AWS documentation for installing ALB controller
   ```

4. **Deploy the Catalog Service** using the Kubernetes manifests

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

**Warning**: This will permanently delete all resources including the database. Make sure to backup any important data first.

## Security Notes

- Database is only accessible from EKS nodes
- All resources are tagged for easy identification
- Secrets are managed through AWS Secrets Manager
- Network traffic is isolated using security groups
- EKS nodes run in private subnets for enhanced security
