# terraform/variables.tf

variable "aws_region" {
  description = "The AWS region to deploy resources in."
  type        = string
  default     = "eu-central-1"
}

variable "project" {
  description = "The name of the project."
  type        = string
  default     = "madeinworld"
}

variable "neon_db_host" {
  description = "Hostname for the Neon PostgreSQL database."
  type        = string
  sensitive   = true
}

variable "neon_db_user" {
  description = "Username for the Neon PostgreSQL database."
  type        = string
  sensitive   = true
}

variable "neon_db_name" {
  description = "Database name for the Neon PostgreSQL database."
  type        = string
}

variable "secret_arn_db_password" {
  description = "ARN of the AWS Secrets Manager secret for the DB password."
  type        = string
  sensitive   = true
}

variable "secret_arn_jwt_secret" {
  description = "ARN of the AWS Secrets Manager secret for the JWT secret."
  type        = string
  sensitive   = true
}

variable "secret_arn_ses_user" {
  description = "ARN of the AWS Secrets Manager secret for the SES SMTP username."
  type        = string
  sensitive   = true
}

variable "secret_arn_ses_pass" {
  description = "ARN of the AWS Secrets Manager secret for the SES SMTP password."
  type        = string
  sensitive   = true
}

variable "ses_from_email" {
  description = "The verified 'From' email address for SES."
  type        = string
}