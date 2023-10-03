terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
}

data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_codecommit_repository" "tf" {
  count           = var.create_codecommit_repo ? 1 : 0
  repository_name = "${var.codecommit_repo_name_prefix_to_watch}${var.resources_name}"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket" "artifacts" {
  # Must be lowercase and less than or equal to 37 characters in length
  bucket_prefix = var.artifacts_bucket_name != "" ? var.artifacts_bucket_name : replace(
    lower(substr("${var.resources_name}-${data.aws_region.current.name}-${data.aws_caller_identity.current.account_id}", 0, 37)),
    "/[ _]/",
    "-"
  )
  force_destroy = var.artifacts_bucket_force_destroy
}

resource "aws_cloudwatch_log_group" "codebuild" {
  name              = "/aws/codebuild/${var.resources_name}"
  retention_in_days = 60
}

resource "aws_iam_role" "codebuild" {
  name_prefix         = "${var.resources_name}-codebuild-"
  managed_policy_arns = var.runner_managed_policy_arns
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
        Action = "sts:AssumeRole",
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "codebuild" {
  role = aws_iam_role.codebuild.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "codebuild:*",
          "codecommit:GitPull",
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:GetAuthorizationToken",
          "ecr:GetDownloadUrlForLayer",
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Resource = "${aws_cloudwatch_log_group.codebuild.arn}:*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:Get*",
          "s3:List*",
          "s3:PutObject",
        ]
        Resource = [
          aws_s3_bucket.artifacts.arn,
          "${aws_s3_bucket.artifacts.arn}/*",
        ]
      },
    ]
  })
}
