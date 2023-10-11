module "codebuild_cicd" {
  source                                     = "../.."
  codebuild_service_role_managed_policy_arns = []
}
