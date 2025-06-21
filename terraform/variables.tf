variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "eu-central-2"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "madeinworld"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "madeinworld_db"
}

variable "db_username" {
  description = "Database username"
  type        = string
  default     = "madeinworld_admin"
}

variable "db_password_secret_name" {
  description = "Name of the AWS Secrets Manager secret containing the database password"
  type        = string
  default     = "madeinworld-db-password"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["eu-central-2a", "eu-central-2b"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.20.0/24"]
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "eks_node_instance_types" {
  description = "EC2 instance types for EKS nodes"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "eks_node_desired_capacity" {
  description = "Desired number of EKS nodes"
  type        = number
  default     = 2
}

variable "eks_node_max_capacity" {
  description = "Maximum number of EKS nodes"
  type        = number
  default     = 4
}

variable "eks_node_min_capacity" {
  description = "Minimum number of EKS nodes"
  type        = number
  default     = 1
}
