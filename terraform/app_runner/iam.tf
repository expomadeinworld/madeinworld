# terraform/app_runner/iam.tf

# Current account
data "aws_caller_identity" "current" {}

# App Runner ECR access role (assumed by App Runner to pull from ECR)
resource "aws_iam_role" "apprunner_ecr_access_role" {
  name = "${var.project}-apprunner-ecr-access-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = { Service = "build.apprunner.amazonaws.com" },
        Action   = "sts:AssumeRole"
      }
    ]
  })
}

# Attach AWS managed policy for ECR access
resource "aws_iam_role_policy_attachment" "apprunner_ecr_access_managed" {
  role       = aws_iam_role.apprunner_ecr_access_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSAppRunnerServicePolicyForECRAccess"
}

# Instance role for running App Runner service (to read Secrets Manager)
resource "aws_iam_role" "apprunner_instance_role" {
  name = "${var.project}-apprunner-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = { Service = "tasks.apprunner.amazonaws.com" },
        Action   = "sts:AssumeRole"
      }
    ]
  })
}

# Construct policy document granting read access to specified secret ARNs
data "aws_iam_policy_document" "apprunner_secrets_doc" {
  dynamic "statement" {
    for_each = toset(local.secret_arns)
    content {
      sid     = "AllowSecret${replace(statement.value, ":", "")}" 
      effect  = "Allow"
      actions = ["secretsmanager:GetSecretValue"]
      resources = [statement.value]
    }
  }
}

# Customer managed policy with least-privilege secret access
resource "aws_iam_policy" "apprunner_secrets_policy" {
  name        = "${var.project}-apprunner-secrets-policy"
  description = "App Runner instance role can read necessary secrets"
  policy      = data.aws_iam_policy_document.apprunner_secrets_doc.json
}

# Attach secrets policy to instance role
resource "aws_iam_role_policy_attachment" "apprunner_secrets_access" {
  role       = aws_iam_role.apprunner_instance_role.name
  policy_arn = aws_iam_policy.apprunner_secrets_policy.arn
}
