module "codebuild_cicd" {
  source                                           = "../.."
  codebuild_service_role_extra_managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonChimeReadOnly"]
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
}

output "codebuild_project_arn" {
  value = module.codebuild_cicd.codebuild_project_arn
}

output "codebuild_service_role_policy_arn" {
  value = module.codebuild_cicd.codebuild_service_role_policy_arn
}
