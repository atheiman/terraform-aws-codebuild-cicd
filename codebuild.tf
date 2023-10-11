resource "aws_iam_role" "codebuild" {
  name_prefix         = "${var.resources_name}-codebuild-"
  managed_policy_arns = var.codebuild_service_role_extra_managed_policy_arns
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
          "codecommit:GitPull",
        ]
        Resource = "*" # TODO: restrict resources for above actions
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

resource "aws_cloudwatch_log_group" "codebuild" {
  name              = "/aws/codebuild/${var.resources_name}"
  retention_in_days = 60
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

resource "aws_s3_bucket_versioning" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_codebuild_project" "cicd" {
  name                   = var.resources_name
  description            = "CI/CD - executes buildspec.yml in CodeCommit repositories on branch events"
  build_timeout          = "120" # minutes
  concurrent_build_limit = var.codebuild_concurrent_build_limit
  service_role           = aws_iam_role.codebuild.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "CI_ARTIFACTS_BUCKET_NAME"
      value = aws_s3_bucket.artifacts.id
    }

    environment_variable {
      name  = "CI_ARTIFACTS_BUCKET_ARN"
      value = aws_s3_bucket.artifacts.arn
    }

    dynamic "environment_variable" {
      for_each = var.codebuild_extra_environment_variables
      iterator = env_var
      content {
        name  = env_var.value["name"]
        value = env_var.value["value"]
      }
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name = aws_cloudwatch_log_group.codebuild.name
    }
  }

  source {
    type = "NO_SOURCE"
    buildspec = yamlencode({
      version = 0.2
      phases = {
        pre_build = {
          commands = [
            "env",
            "date",
          ]
        }
        build = {
          commands = [
            "echo add a buildspec.yml to your project to run build commands",
          ]
        }
      }
    })
  }
}
