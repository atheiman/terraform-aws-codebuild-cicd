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
          "codecommit:PostCommentForPullRequest",
        ]
        Resource = "*"
      },
    ]
  })
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${aws_lambda_function.pull_request_build_status.function_name}"
  retention_in_days = 60
}

data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_lambda_function" "pull_request_build_status" {
  function_name    = "${var.resources_name}-pull-request-build-status"
  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256
  handler          = "pull_request_build_status.handler"
  role             = aws_iam_role.lambda.arn
  runtime          = "python3.8"
  timeout          = 10

  environment {
    variables = {
      PULL_REQUEST_EVENTS_RULE_NAME = aws_cloudwatch_event_rule.codecommit_pull_requests.name
    }
  }
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "EventBridgeRule"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.pull_request_build_status.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.codebuild_builds.arn
}
