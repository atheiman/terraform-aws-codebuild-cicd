resource "aws_iam_role" "lambda" {
  name_prefix         = "${var.resources_name}-lambda-"
  managed_policy_arns = ["arn:${data.aws_partition.current.id}:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"]
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
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

resource "aws_iam_role_policy" "lambda" {
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "codecommit:GetFile",
          "codecommit:GetPullRequest",
          "codecommit:GetRepository",
          "codecommit:PostCommentForPullRequest",
          "codecommit:UpdatePullRequestApprovalState",
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = "codebuild:StartBuild",
        Resource = aws_codebuild_project.cicd.arn
      },
    ]
  })
}

data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/lambda.zip"
}

# CodeBuild start build

resource "aws_lambda_function" "codebuild_start_build" {
  function_name    = "${var.resources_name}-codebuild-start-build"
  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256
  handler          = "codebuild_start_build.handler"
  role             = aws_iam_role.lambda.arn
  runtime          = "python3.9"
  timeout          = 10

  environment {
    variables = {
      CODEBUILD_PROJECT_NAME                       = aws_codebuild_project.cicd.name
      CODEBUILD_LOAD_BUILDSPEC_FROM_DEFAULT_BRANCH = var.codebuild_load_buildspec_from_default_branch
    }
  }
}

resource "aws_cloudwatch_log_group" "lambda_codebuild_start_build" {
  name              = "/aws/lambda/${aws_lambda_function.codebuild_start_build.function_name}"
  retention_in_days = 60
}

resource "aws_lambda_permission" "codebuild_start_build_cloudwatch_codecommit_branch_push" {
  statement_id_prefix = "EventBridgeRuleCodeCommitBranchPush"
  action              = "lambda:InvokeFunction"
  function_name       = aws_lambda_function.codebuild_start_build.function_name
  principal           = "events.amazonaws.com"
  source_arn          = aws_cloudwatch_event_rule.codecommit_branch_push.arn
}

resource "aws_lambda_permission" "codebuild_start_build_cloudwatch_codecommit_pull_requests" {
  statement_id_prefix = "EventBridgeRuleCodeCommitPullRequests"
  action              = "lambda:InvokeFunction"
  function_name       = aws_lambda_function.codebuild_start_build.function_name
  principal           = "events.amazonaws.com"
  source_arn          = aws_cloudwatch_event_rule.codecommit_pull_requests.arn
}

# Pull request build status

resource "aws_lambda_function" "pull_request_build_status" {
  function_name    = "${var.resources_name}-pull-request-build-status"
  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256
  handler          = "pull_request_build_status.handler"
  role             = aws_iam_role.lambda.arn
  runtime          = "python3.9"
  timeout          = 10

  environment {
    variables = {
      PULL_REQUEST_EVENTS_RULE_NAME = aws_cloudwatch_event_rule.codecommit_pull_requests.name
    }
  }
}

resource "aws_cloudwatch_log_group" "lambda_pull_request_build_status" {
  name              = "/aws/lambda/${aws_lambda_function.pull_request_build_status.function_name}"
  retention_in_days = 60
}

resource "aws_lambda_permission" "pull_request_build_status_cloudwatch" {
  statement_id_prefix = "EventBridgeRule"
  action              = "lambda:InvokeFunction"
  function_name       = aws_lambda_function.pull_request_build_status.function_name
  principal           = "events.amazonaws.com"
  source_arn          = aws_cloudwatch_event_rule.codebuild_builds.arn
}
