resource "aws_iam_role" "codebuild" {
  name_prefix         = "${var.resources_name}-codebuild-"
  managed_policy_arns = concat(var.codebuild_service_role_extra_managed_policy_arns, [aws_iam_policy.codebuild.arn])
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

resource "aws_iam_policy" "codebuild" {
  name_prefix = "${var.resources_name}-codebuild-"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "codecommit:GitPull",
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
    ]
  })
}

resource "aws_cloudwatch_log_group" "codebuild" {
  name              = "/aws/codebuild/${var.resources_name}" # must match codebuild project name
  retention_in_days = 60
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
