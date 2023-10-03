output "codecommit_repo_clone_url_http" {
  value = length(aws_codecommit_repository.tf) > 0 ? aws_codecommit_repository.tf[0].clone_url_http : null
}

output "codecommit_repo_clone_url_ssh" {
  value = length(aws_codecommit_repository.tf) > 0 ? aws_codecommit_repository.tf[0].clone_url_ssh : null
}

