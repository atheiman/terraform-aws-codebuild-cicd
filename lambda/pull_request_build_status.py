# Inspired by https://github.com/aws-samples/aws-codecommit-pull-request-aws-codebuild
# Receives EventBridge events like the below example, and comments build status messages on the
# related pull request if it exists.

# {
#   "version":"0",
#   "id":"ca9f54f0-0e11-d15c-f3ff-e27b42d1ec1e",
#   "detail-type":"CodeBuild Build State Change",
#   "source":"aws.codebuild",
#   "account":"111111111111",
#   "time":"2023-10-10T20:43:22Z",
#   "region":"us-east-1",
#   "resources":[
#     "arn:aws:codebuild:us-east-1:111111111111:build/codebuild-cicd:49e2bfa6-2222-47f5-a959-a77e6bf007fd"
#   ],
#   "detail":{
#     "build-status":"IN_PROGRESS",
#     "project-name":"codebuild-cicd",
#     "build-id":"arn:aws:codebuild:us-east-1:111111111111:build/codebuild-cicd:49e2bfa6-2222-47f5-a959-a77e6bf007fd",
#     "additional-information":{
#       "initiator":"rule/codebuild-cicd-default-branches20231003133630874300000001",
#       "environment":{
#         "environment-variables":[ ... ],
#         ...
#       },
#       ...
#     },
#     ...
#   }
# }

import datetime
import boto3
import os
import json

codecommit = boto3.client("codecommit", region_name=os.environ["AWS_REGION"])


def handler(event, context):
    print(json.dumps(event))
    if event["detail-type"] != "CodeBuild Build State Change":
        raise Exception(f"Error - Unexpected event received, detail-type: '{event['detail-type']}'")

    pull_request_id = None
    repository_name = None
    source_commit = None
    destination_commit = None

    for env_var in event["detail"]["additional-information"]["environment"]["environment-variables"]:
        if env_var["name"] == "CI_PULL_REQUEST_ID":
            pull_request_id = env_var["value"]
        elif env_var["name"] == "CI_REPOSITORY_NAME":
            repository_name = env_var["value"]
        elif env_var["name"] == "CI_SOURCE_COMMIT":
            source_commit = env_var["value"]
        elif env_var["name"] == "CI_DESTINATION_COMMIT":
            destination_commit = env_var["value"]

    if not pull_request_id or not repository_name or not source_commit or not destination_commit:
        initiator = event["detail"]["additional-information"]["initiator"]
        print(
            "Did not find pull request attributes in build env vars. Build initiator is likely not the pull"
            f" request events rule {os.environ['PULL_REQUEST_EVENTS_RULE_NAME']}. Build initiator: {initiator}"
        )
        return

    pr = codecommit.get_pull_request(pullRequestId=pull_request_id)["pullRequest"]

    build_arn = event["detail"]["build-id"]
    build_arn_elements = build_arn.split(":")
    build_region = build_arn_elements[3]
    build_id = build_arn_elements[-1]
    build_link = f"/codesuite/codebuild/projects/{event['detail']['project-name']}/build/{event['detail']['project-name']}:{build_id}?region={build_region}"

    if event["detail"]["build-status"] == "SUCCEEDED":
        content = b"\\u2705 ".decode("unicode-escape")  # heavy check mark
        # Approve the pull request - approvals are automatically removed when new commits are pushed to the pull request.
        codecommit.update_pull_request_approval_state(
            pullRequestId=pull_request_id, revisionId=pr["revisionId"], approvalState="APPROVE"
        )
    elif event["detail"]["build-status"] in ["FAILED", "STOPPED"]:
        content = b"\\u274c ".decode("unicode-escape")  # X ("cross mark")
    elif event["detail"]["build-status"] in ["IN_PROGRESS"]:
        content = b"\\u23f1 ".decode("unicode-escape")  # stopwatch
    content += f"CodeBuild build **{event['detail']['build-status']}** for commit `{source_commit[0:8]}`: [`{build_id}`]({build_link})"

    codecommit.post_comment_for_pull_request(
        pullRequestId=pull_request_id,
        repositoryName=repository_name,
        beforeCommitId=source_commit,
        afterCommitId=destination_commit,
        content=content,
    )
