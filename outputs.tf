output "codebuild_project_arn" {
  value = aws_codebuild_project.cicd.arn
}

output "codebuild_service_role_policy_arn" {
  value = aws_iam_policy.codebuild.arn
}

output "codecommit_approval_rule_template_name" {
  value = aws_codecommit_approval_rule_template.cicd.name
}
