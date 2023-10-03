resource "aws_codebuild_project" "cicd_runner" {
  name          = var.resources_name
  description   = "Terraform plan and apply actions"
  build_timeout = "120" # minutes
  service_role  = aws_iam_role.codebuild.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  # environment_variable {
  #   name  = "SOME_KEY1"
  #   value = "SOME_VALUE1"
  # }

  # logs_config {
  #   cloudwatch_logs {
  #     group_name  = aws_cloudwatch_log_group.codebuild.name
  #   }
  # }

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
