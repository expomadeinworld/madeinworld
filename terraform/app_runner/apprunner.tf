# terraform/app_runner/apprunner.tf

data "aws_caller_identity" "current" {}

# --- NEW: IAM ROLE FOR ECR ACCESS (ROLE A) ---
resource "aws_iam_role" "apprunner_ecr_access_role" {
  name = "${var.project}-apprunner-ecr-access-role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = {
          Service = "build.apprunner.amazonaws.com"
        }
        Action    = "sts:AssumeRole"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "apprunner_ecr_access" {
  role       = aws_iam_role.apprunner_ecr_access_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSAppRunnerServicePolicyForECRAccess"
}


# --- NEW: IAM ROLE FOR INSTANCE/SECRET ACCESS (ROLE B) ---
resource "aws_iam_role" "apprunner_instance_role" {
  name = "${var.project}-apprunner-instance-role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = {
          Service = "tasks.apprunner.amazonaws.com"
        }
        Action    = "sts:AssumeRole"
      },
    ]
  })
}

resource "aws_iam_policy" "apprunner_secrets_policy" {
  name   = "${var.project}-apprunner-secrets-policy"
  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "secretsmanager:GetSecretValue"
        Resource = [ # This policy grants access to the specific secrets needed
          var.secret_arn_db_password,
          var.secret_arn_jwt_secret,
          var.secret_arn_ses_user,
          var.secret_arn_ses_pass,
        ]
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "apprunner_secrets_access" {
  role       = aws_iam_role.apprunner_instance_role.name
  policy_arn = aws_iam_policy.apprunner_secrets_policy.arn
}


# --- EXISTING RESOURCES, NOW MODIFIED ---
locals {
  services = {
    auth-service    = "8081"
    catalog-service = "8080"
    order-service   = "8082"
    user-service    = "8083"
  }
}

resource "aws_ecr_repository" "service_repos" {
  for_each = local.services
  name     = "${var.project}/${each.key}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_apprunner_service" "main_services" {
  for_each      = local.services
  service_name  = "${var.project}-${each.key}-dev"

  source_configuration {
    authentication_configuration {
      # MODIFIED: Attaching the ECR Access Role
      access_role_arn = aws_iam_role.apprunner_ecr_access_role.arn
    }
    image_repository {
      image_identifier      = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.project}/${each.key}:latest"
      image_repository_type = "ECR"
      image_configuration {
        port = each.value
        runtime_environment_variables = {
          PORT               = each.value
          GIN_MODE           = "release"
          DB_HOST            = var.neon_db_host
          DB_PORT            = "5432"
          DB_USER            = var.neon_db_user
          DB_NAME            = var.neon_db_name
          DB_SSLMODE         = "require"
          SES_FROM_EMAIL     = var.ses_from_email
          AWS_DEFAULT_REGION = var.aws_region
        }
        runtime_environment_secrets = {
          DB_PASSWORD           = var.secret_arn_db_password
          JWT_SECRET            = var.secret_arn_jwt_secret
          AWS_ACCESS_KEY_ID     = var.secret_arn_ses_user
          AWS_SECRET_ACCESS_KEY = var.secret_arn_ses_pass
        }
      }
    }
    auto_deployments_enabled = true
  }

  instance_configuration {
    # MODIFIED: Attaching the Instance Role for Secrets access
    instance_role_arn = aws_iam_role.apprunner_instance_role.arn
  }

  health_check_configuration {
    protocol = "HTTP"
    path     = "/health"
  }

  tags = {
    Project = var.project
    Phase   = "1"
  }
}