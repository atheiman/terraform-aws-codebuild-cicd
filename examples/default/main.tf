data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

module "codebuild_cicd" {
  source                                                    = "../.."
  codebuild_service_role_extra_managed_policy_arns          = ["arn:${data.aws_partition.current.id}:iam::aws:policy/AmazonChimeReadOnly"]
  codecommit_approval_rule_template_associated_repositories = ["example-cicd-usage"]
  codebuild_extra_environment_variables = [
    {
      name  = "CI_MY_COLOR"
      value = "blue"
    },
    {
      name  = "CI_MY_NUMBER"
      value = 4
    },
  ]
  codecommit_repositories_customizations = {
    "example-cicd-usage" = {
      codebuild_service_role_arn = aws_iam_role.codebuild_service_role.arn
    }
  }
  codecommit_repositories_allowed = ["example-cicd-usage"]
  # deny list is not necessary because allow list defined above
  codecommit_repositories_denied = ["never-build-this-repo"]
}

resource "aws_iam_role" "codebuild_service_role" {
  name_prefix = "codebuild"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codebuild_service_role_policy" {
  role       = aws_iam_role.codebuild_service_role.name
  policy_arn = module.codebuild_cicd.codebuild_service_role_policy_arn
}

resource "aws_iam_role_policy_attachment" "codebuild_service_role_s3_readonlyaccess" {
  role       = aws_iam_role.codebuild_service_role.name
  policy_arn = "arn:${data.aws_partition.current.id}:iam::aws:policy/AmazonDynamoDBReadOnlyAccess"
}

output "codebuild_project_arn" {
  value = module.codebuild_cicd.codebuild_project_arn
}

output "codebuild_service_role_policy_arn" {
  value = module.codebuild_cicd.codebuild_service_role_policy_arn
}

output "codecommit_approval_rule_template_name" {
  value = module.codebuild_cicd.codecommit_approval_rule_template_name
}
