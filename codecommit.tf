resource "aws_codecommit_approval_rule_template" "cicd" {
  name        = var.resources_name
  description = "Require approval from CodeBuild CI/CD"

  content = jsonencode({
    Version = "2018-11-08"
    Statements = [{
      Type                    = "Approvers"
      NumberOfApprovalsNeeded = 1
      ApprovalPoolMembers = [
        "arn:${data.aws_partition.current.id}:sts::${data.aws_caller_identity.current.account_id}:assumed-role/${aws_iam_role.lambda.name}/${aws_lambda_function.pull_request_build_status.function_name}"
      ]
    }]
  })
}

resource "aws_codecommit_approval_rule_template_association" "cicd" {
  for_each                    = toset(var.codecommit_approval_rule_template_associated_repositories)
  approval_rule_template_name = aws_codecommit_approval_rule_template.cicd.name
  repository_name             = each.key
}
