# Example 'CodeCommit Repository State Change' event
# {
#     "version": "0",
#     "id": "3f7101d2-f1c4-d0a4-6d89-69fc887cc5e4",
#     "detail-type": "CodeCommit Repository State Change",
#     "source": "aws.codecommit",
#     "account": "111111111111",
#     "time": "2023-10-10T21:05:45Z",
#     "region": "us-east-1",
#     "resources": ["arn:aws:codecommit:us-east-1:111111111111:some-repo"],
#     "detail": {
#         "callerUserArn": "arn:aws:iam::111111111111:user/admin",
#         "commitId": "f485fcc95a795517f279d0a877227e51208b0dfc",
#         "event": "referenceUpdated",
#         "oldCommitId": "a399698fbd740af9c78fb2dd7f667656b70646b6",
#         "referenceFullName": "refs/heads/main",
#         "referenceName": "main",
#         "referenceType": "branch",
#         "repositoryId": "280e6f04-7a9c-4c72-8d8f-947d83e21a96",
#         "repositoryName": "some-repo"
#     }
# }
resource "aws_cloudwatch_event_rule" "codecommit_branch_push" {
  name_prefix = substr("${var.resources_name}-branch-push-", 0, 38)
  description = "Start CodeBuild CI/CD on CodeCommit repositories branch events."

  event_pattern = jsonencode({
    source      = ["aws.codecommit"]
    detail-type = ["CodeCommit Repository State Change"]
    detail = {
      event = ["referenceCreated", "referenceUpdated"]
    }
  })
}

resource "aws_cloudwatch_event_target" "codecommit_branch_push_lambda" {
  rule      = aws_cloudwatch_event_rule.codecommit_branch_push.name
  target_id = "Lambda"
  arn       = aws_lambda_function.codebuild_start_build.arn
}

# Example 'CodeCommit Pull Request State Change' event
# {
#     "version": "0",
#     "id": "6d29aaa0-f4a6-7745-6ec1-cf1587935aef",
#     "detail-type": "CodeCommit Pull Request State Change",
#     "source": "aws.codecommit",
#     "account": "111111111111",
#     "time": "2023-10-10T21:33:04Z",
#     "region": "us-east-1",
#     "resources": ["arn:aws:codecommit:us-east-1:111111111111:some-repo"],
#     "detail": {
#         "author": "arn:aws:sts::111111111111:assumed-role/some-role/some-session",
#         "callerUserArn": "arn:aws:sts::111111111111:assumed-role/some-role/some-session",
#         "creationDate": "Tue Oct 10 21:32:51 UTC 2023",
#         "destinationCommit": "6a3cf62d6b847143c58d8fcbb50dfd61f1ca2450",
#         "destinationReference": "refs/heads/main",
#         "event": "pullRequestCreated",
#         "isMerged": "False",
#         "lastModifiedDate": "Tue Oct 10 21:32:51 UTC 2023",
#         "notificationBody": "A pull request event occurred ...",
#         "pullRequestId": "1",
#         "pullRequestStatus": "Open",
#         "repositoryNames": ["some-repo"],
#         "revisionId": "a4b86e55d3c8110b527e7b1cbcbc3269dbe8aa53e6b0c436791346cd45ac82a0",
#         "sourceCommit": "5c020b042dd71daa6e6cade586cf862a2e7e4f96",
#         "sourceReference": "refs/heads/feature-branch",
#         "title": "some feature"
#     }
# }
resource "aws_cloudwatch_event_rule" "codecommit_pull_requests" {
  name_prefix = substr("${var.resources_name}-pull-requests-", 0, 38)
  description = "Start CodeBuild CI/CD on CodeCommit repositories pull request events."

  event_pattern = jsonencode({
    source      = ["aws.codecommit"]
    detail-type = ["CodeCommit Pull Request State Change"]
    detail = {
      event = [
        "pullRequestCreated",
        "pullRequestSourceBranchUpdated",
      ]
    }
  })
}

resource "aws_cloudwatch_event_target" "codecommit_pull_requests_lambda" {
  rule      = aws_cloudwatch_event_rule.codecommit_pull_requests.name
  target_id = "Lambda"
  arn       = aws_lambda_function.codebuild_start_build.arn
}


# Example 'CodeBuild Build State Change' event
# {
#     "version": "0",
#     "id": "e69ed76e-4a16-243a-f799-95bd341e2787",
#     "detail-type": "CodeBuild Build State Change",
#     "source": "aws.codebuild",
#     "account": "111111111111",
#     "time": "2023-10-10T21:46:46Z",
#     "region": "us-east-1",
#     "resources": [
#         "arn:aws:codebuild:us-east-1:111111111111:build/codebuild-cicd:171322d8-15cf-4cb2-9ee2-3e45c39538a3"
#     ],
#     "detail": {
#         "build-status": "IN_PROGRESS",
#         "project-name": "codebuild-cicd",
#         "build-id": "arn:aws:codebuild:us-east-1:111111111111:build/codebuild-cicd:171322d8-15cf-4cb2-9ee2-3e45c39538a3",
#         "additional-information": {
#             "cache": {
#                 "type": "NO_CACHE"
#             },
#             "timeout-in-minutes": 120,
#             "build-complete": false,
#             "initiator": "rule/codebuild-cicd-builds-20231003144740013100000001",
#             "build-start-time": "Oct 10, 2023 9:46:46 PM",
#             "source": {
#                 "buildspec": "buildspec.yml",
#                 "location": "https://git-codecommit.us-east-1.amazonaws.com/v1/repos/some-repo",
#                 "git-clone-depth": 0,
#                 "type": "CODECOMMIT"
#             },
#             "source-version": "5c020b042dd71daa6e6cade586cf862a2e7e4f96",
#             "artifact": {
#                 "location": ""
#             },
#             "environment": {
#                 "image": "aws/codebuild/amazonlinux2-x86_64-standard:5.0",
#                 "privileged-mode": false,
#                 "image-pull-credentials-type": "CODEBUILD",
#                 "compute-type": "BUILD_GENERAL1_SMALL",
#                 "type": "LINUX_CONTAINER",
#                 "environment-variables": [
#                     {
#                         "name": "CI_SOURCE_COMMIT",
#                         "type": "PLAINTEXT",
#                         "value": "5c020b042dd71daa6e6cade586cf862a2e7e4f96"
#                     },
#                     {
#                         "name": "CI_PULL_REQUEST_ID",
#                         "type": "PLAINTEXT",
#                         "value": "2"
#                     },
#                     {
#                         "name": "CI_DESTINATION_COMMIT",
#                         "type": "PLAINTEXT",
#                         "value": "6a3cf62d6b847143c58d8fcbb50dfd61f1ca2450"
#                     },
#                     {
#                         "name": "CI_REPOSITORY_NAME",
#                         "type": "PLAINTEXT",
#                         "value": "some-repo"
#                     }
#                 ]
#             },
#             "logs": {
#                 "deep-link": "https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#logsV2:log-groups"
#             },
#             "queued-timeout-in-minutes": 480
#         },
#         "current-phase": "SUBMITTED",
#         "current-phase-context": "[]",
#         "version": "1"
#     }
# }
resource "aws_cloudwatch_event_rule" "codebuild_builds" {
  name_prefix = substr("${var.resources_name}-builds-", 0, 38)
  description = "Invoke CodeBuild CI/CD Lambda function on CodeBuild build state change events. Lambda function will comment build info on CodeCommit repositories pull requests if the build is related to a pull request."

  event_pattern = jsonencode({
    source      = ["aws.codebuild"]
    detail-type = ["CodeBuild Build State Change"]
    detail = {
      project-name = [aws_codebuild_project.cicd.name]
    }
  })
}

resource "aws_cloudwatch_event_target" "codebuild_builds_lambda" {
  rule      = aws_cloudwatch_event_rule.codebuild_builds.name
  target_id = "Lambda"
  arn       = aws_lambda_function.pull_request_build_status.arn
}
