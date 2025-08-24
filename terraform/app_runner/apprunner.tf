# terraform/app_runner/apprunner.tf

locals {
  db_secret_base  = replace(var.secret_arn_db_password, "/:[^:]+::$/", "")
  jwt_secret_base = replace(var.secret_arn_jwt_secret,  "/:[^:]+::$/", "")
  ses_user_base   = replace(var.secret_arn_ses_user,     "/:[^:]+::$/", "")
  ses_pass_base   = replace(var.secret_arn_ses_pass,     "/:[^:]+::$/", "")

  # Ensure we always use Neon connection pooler. If the provided host already contains
  # "-pooler.", keep it as-is. Otherwise, insert "-pooler" before the first dot.
  neon_host_parts         = split(".", var.neon_db_host)
  neon_pooler_host_guess  = format("%s-pooler.%s", local.neon_host_parts[0], join(".", slice(local.neon_host_parts, 1, length(local.neon_host_parts))))
  neon_effective_db_host  = can(regex("-pooler\\.", var.neon_db_host)) ? var.neon_db_host : local.neon_pooler_host_guess
}

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
        Effect = "Allow"
        Action = "secretsmanager:GetSecretValue"
        Resource = [
          local.db_secret_base,  var.secret_arn_db_password,
          local.jwt_secret_base, var.secret_arn_jwt_secret,
          local.ses_user_base,   var.secret_arn_ses_user,
          local.ses_pass_base,   var.secret_arn_ses_pass,
        ]
      }
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
      access_role_arn = aws_iam_role.apprunner_ecr_access_role.arn
    }
    image_repository {
      image_identifier      = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.project}/${each.key}:latest"
      image_repository_type = "ECR"
      image_configuration {
        port = each.value
        runtime_environment_variables = merge({
          PORT               = each.value
          GIN_MODE           = "release"
          DB_HOST            = local.neon_effective_db_host
          DB_PORT            = "5432"
          DB_USER            = var.neon_db_user
          DB_NAME            = var.neon_db_name
          DB_SSLMODE         = "require"
          SES_FROM_EMAIL     = var.ses_from_email
          AWS_DEFAULT_REGION = var.aws_region
        }, each.key == "catalog-service" ? {
          SERVICE_BASE_URL = "https://device-api.expomadeinworld.com"
        } : each.key == "auth-service" ? {
          ADMIN_EMAIL = "expotobsrl@gmail.com"
        } : {})
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
    instance_role_arn = aws_iam_role.apprunner_instance_role.arn
  }

  health_check_configuration {
    protocol = "HTTP"
    path     = "/live"
  }

  tags = {
    Project = var.project
    Phase   = "1"
  }
}