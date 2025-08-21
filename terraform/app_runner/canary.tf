# CloudWatch Synthetics Canary for auth-service /ready endpoint

locals {
  synthetics_bucket_name = "${var.project}-synthetics-artifacts"
}

resource "aws_s3_bucket" "synthetics_artifacts" {
  bucket        = local.synthetics_bucket_name
  force_destroy = true
}

resource "aws_iam_role" "synthetics_role" {
  name = "${var.project}-synthetics-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action = "sts:AssumeRole"
    },{
      Effect = "Allow"
      Principal = { Service = "synthetics.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "synthetics_full_access" {
  role       = aws_iam_role.synthetics_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchSyntheticsFullAccess"
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.synthetics_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "s3_rw" {
  role       = aws_iam_role.synthetics_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# Canary that polls auth-service /ready every 2 minutes
resource "aws_synthetics_canary" "auth_ready" {
  name                 = "${var.project}-auth-ready"
  artifact_s3_location = "s3://${aws_s3_bucket.synthetics_artifacts.bucket}"
  execution_role_arn   = aws_iam_role.synthetics_role.arn
  handler              = "index.handler"
  runtime_version      = "syn-nodejs-puppeteer-6.2"
  start_canary         = true
  schedule {
    expression = var.canary_schedule_expression
  }

  code {
    handler = "index.handler"
    script  = <<-EOT
      const synthetics = require('Synthetics');
      const log = require('SyntheticsLogger');
      const https = require('https');

      const apiCanaryBlueprint = async function () {
        const url = process.env.TARGET_URL;
        const u = new URL(url);
        const options = {
          hostname: u.hostname,
          path: u.pathname + (u.search || ''),
          method: 'GET',
          port: 443,
          protocol: 'https:'
        };
        await synthetics.executeHttpStep('auth-ready', options, async (res) => {
          if (res.statusCode !== 200) {
            throw new Error('Non-200 status: ' + res.statusCode);
          }
        });
      };

      exports.handler = async () => {
        return await apiCanaryBlueprint();
      };
    EOT
  }

  environment_variables = {
    TARGET_URL = "${aws_apprunner_service.main_services["auth-service"].service_url}/ready"
  }
}

variable "canary_schedule_expression" {
  description = "Schedule for the readiness canary"
  type        = string
  default     = "rate(2 minutes)"
}

