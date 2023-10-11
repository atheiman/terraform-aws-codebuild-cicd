module "codebuild_cicd" {
  source                                           = "../.."
  codebuild_service_role_extra_managed_policy_arns = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
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
