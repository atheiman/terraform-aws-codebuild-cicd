module "codebuild_cicd_runner" {
  source = "../.."
}

output "codecommit_repo_clone_url_http" {
  value = module.codebuild_cicd_runner.codecommit_repo_clone_url_http
}

output "codecommit_repo_clone_url_ssh" {
  value = module.codebuild_cicd_runner.codecommit_repo_clone_url_ssh
}
